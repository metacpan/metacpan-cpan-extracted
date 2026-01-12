package Claude::Agent::CLI;

use 5.020;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Term::ANSIColor qw(:constants colored);
use Term::ReadLine;
use Term::Choose qw(choose);
use Term::ProgressSpinner;
use Exporter 'import';

our @EXPORT_OK = qw(
    with_spinner start_spinner stop_spinner
    prompt ask_yn menu select_option choose_from choose_multiple
    header divider status
    clear_line move_up
);

our %EXPORT_TAGS = (
    all     => \@EXPORT_OK,
    spinner => [qw(with_spinner start_spinner stop_spinner)],
    prompt  => [qw(prompt ask_yn menu select_option choose_from choose_multiple)],
    display => [qw(header divider status)],
    term    => [qw(clear_line move_up)],
);

=head1 NAME

Claude::Agent::CLI - Terminal UI utilities for interactive CLI applications

=head1 SYNOPSIS

    use Claude::Agent::CLI qw(:all);

    # Spinners
    my $result = with_spinner("Processing...", sub {
        # Long-running operation
        return $data;
    });

    # Async spinners with IO::Async
    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $spinner = start_spinner("Processing...", $loop);
    my $result = await $async_operation;
    stop_spinner($spinner, "Processing complete");

    # Prompts
    my $name = prompt("Enter your name", "Anonymous");
    my $continue = ask_yn("Continue?", "y");
    my $choice = menu("Select action", [
        { key => 'a', label => 'Add' },
        { key => 'd', label => 'Delete' },
    ]);

    # Interactive selection using Term::Choose (keyboard navigation)
    my $selected = choose_from(\@options, prompt => "Pick one:");
    my @selected = choose_multiple(\@options, prompt => "Pick several:");

    # Display utilities
    header("My Application");
    divider();
    status('success', "Operation completed");
    status('error', "Something went wrong");

=head1 DESCRIPTION

Provides shared utilities for interactive terminal features including:

=over 4

=item * Spinners using Term::ProgressSpinner (with IO::Async support)

=item * Input prompts using Term::ReadLine

=item * Interactive keyboard-navigable selection using Term::Choose

=item * Colored output using Term::ANSIColor

=item * Terminal control utilities

=back

=head1 EXPORTS

Nothing is exported by default. Use C<:all> for everything, or import specific functions.

=head2 Export Tags

    :all     - All functions
    :spinner - with_spinner, start_spinner, stop_spinner
    :prompt  - prompt, ask_yn, menu, select_option, choose_from, choose_multiple
    :display - header, divider, status
    :term    - clear_line, move_up

=cut

# Terminal singleton for Term::ReadLine
my $_term;

sub _term {
    $_term //= Term::ReadLine->new('Claude::Agent');
}

=head1 FUNCTIONS

=head2 Spinners

=head3 with_spinner

    my $result = with_spinner($message, $code);

Display a spinner while executing code. Returns the result of the code block.
Note: This is for synchronous code. For async operations, use start_spinner/stop_spinner.

    my $data = with_spinner("Loading...", sub {
        return load_data();
    });

=cut

sub with_spinner {
    my ($message, $code) = @_;

    my $ps = Term::ProgressSpinner->new();
    $ps->message("{spinner} $message");
    $ps->start(100);  # Indeterminate mode

    my $result = $code->();

    $ps->finish();
    status('success', $message);

    return $result;
}

=head3 start_spinner

    my $spinner = start_spinner($message, $loop, %opts);

Start an async spinner for long-running operations. Returns the spinner object.
Call stop_spinner($spinner) when the operation completes.

When an IO::Async loop is provided, the spinner animates automatically.
Without a loop, the spinner displays but doesn't animate (useful for quick operations).

Options:

    spinner        - Spinner style (default: 'dots')
                     Available: dots, bar, around, pipe, moon, circle,
                     color_circle, color_circles, color_square, color_squares,
                     earth, circle_half, clock, pong, material
    spinner_color  - Color for spinner (default: 'cyan')
                     Available: black, red, green, yellow, blue, magenta, cyan, white
                     Also: bright_* variants, and "color on_background" combinations
    message        - Custom message format (default: "{spinner} $message")
                     Placeholders: {spinner}, {elapsed}, {percent}, etc.
    interval       - Animation interval in seconds (default: 0.1)
    terminal_line  - Skip STDIN cursor query by providing line number

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    # Simple usage
    my $spinner = start_spinner("Processing...", $loop);

    # Customized spinner
    my $spinner = start_spinner("Loading...", $loop,
        spinner       => 'moon',
        spinner_color => 'yellow',
        interval      => 0.2,
    );

    my $result = await $async_operation;
    stop_spinner($spinner, "Processing complete");

=cut

my $_active_spinner;

sub start_spinner {
    my ($message, $loop, %opts) = @_;

    # Extract our options vs Term::ProgressSpinner options
    my $interval = delete $opts{interval} // 0.1;

    # Build spinner options with defaults
    my %spinner_opts = (
        spinner       => $opts{spinner}       // 'dots',
        spinner_color => $opts{spinner_color} // 'cyan',
        message       => $opts{message}       // "{spinner} $message",
    );

    # Pass through any additional Term::ProgressSpinner options
    for my $key (qw(terminal_line terminal_height output)) {
        $spinner_opts{$key} = $opts{$key} if defined $opts{$key};
    }

    $_active_spinner = Term::ProgressSpinner->new(%spinner_opts);

    if ($loop) {
        # Async mode - spinner animates via IO::Async timer
        $_active_spinner->start_async($loop, interval => $interval);
    } else {
        # Non-async mode - start and draw once
        $_active_spinner->start(1);
        $_active_spinner->draw($_active_spinner);
    }

    return $_active_spinner;
}

=head3 stop_spinner

    stop_spinner($spinner, $success_message);

Stop a spinner started with start_spinner. Optionally display a success message.

=cut

sub stop_spinner {
    my ($spinner, $success_message) = @_;

    $spinner //= $_active_spinner;
    return unless $spinner;

    if ($spinner->{_async_timer}) {
        # Async mode - use stop_async
        $spinner->stop_async($success_message);
    } else {
        # Non-async mode - finish and show message
        $spinner->finish();
        status('success', $success_message) if $success_message;
    }

    $_active_spinner = undef;
}

=head2 Prompts

=head3 prompt

    my $answer = prompt($message, $default);

Prompt the user for text input with an optional default value.

=cut

sub prompt {
    my ($message, $default) = @_;
    my $prompt_str = $message;
    $prompt_str .= " [$default]" if defined $default && $default ne '';
    $prompt_str .= ": ";

    my $answer = _term->readline($prompt_str);
    $answer //= '';
    $answer =~ s/^\s+|\s+$//g;

    return ($answer ne '' ? $answer : $default) // '';
}

=head3 ask_yn

    my $yes = ask_yn($message, $default);

Ask a yes/no question. Returns true for yes, false for no.
Default is 'y' if not specified.

    if (ask_yn("Continue?", "y")) {
        # User said yes
    }

=cut

sub ask_yn {
    my ($message, $default) = @_;
    $default //= 'y';

    # Use Term::Choose for interactive yes/no
    my @options = $default =~ /^y/i
        ? ('Yes', 'No')
        : ('No', 'Yes');

    my $choice = choose(
        \@options,
        {
            prompt => "$message ",
            layout => 1,  # Horizontal layout
        }
    );

    return unless defined $choice;  # Cancelled
    return $choice eq 'Yes';
}

=head3 menu

    my $choice = menu($title, $options);

Display a menu with keyed options using Term::Choose for keyboard navigation.
Returns the selected key.

    my $action = menu("Action", [
        { key => 'a', label => 'Approve' },
        { key => 'r', label => 'Revise' },
        { key => 's', label => 'Skip' },
    ]);

=cut

sub menu {
    my ($title, $options) = @_;

    # Build display labels for Term::Choose
    my @labels = map { "[$_->{key}] $_->{label}" } @$options;

    my $choice = choose(
        \@labels,
        {
            prompt => "$title:",
            layout => 2,  # Single column
        }
    );

    return unless defined $choice;

    # Extract key from selected label "[k] Label"
    if ($choice =~ /^\[(\w+)\]/) {
        return $1;
    }
    return $options->[0]{key};
}

=head3 select_option

    my $selected = select_option($options, %args);

Display options for selection using Term::Choose with keyboard navigation.
Returns the selected option text, or undef if "Custom" was selected
(when allow_custom => 1).

    my $outline = select_option(\@outlines, allow_custom => 1);
    if (!defined $outline) {
        # User wants to enter custom text
        $outline = prompt("Enter custom outline:");
    }

=cut

sub select_option {
    my ($options, %args) = @_;

    # Build display list with previews
    my @display;
    for my $i (0 .. $#$options) {
        my $preview = substr($options->[$i], 0, 60);
        $preview .= "..." if length($options->[$i]) > 60;
        $preview =~ s/\n/ /g;  # Replace newlines with spaces
        push @display, "[$i] $preview";
    }

    if ($args{allow_custom}) {
        push @display, "[c] Custom";
    }

    my $choice = choose(
        \@display,
        {
            prompt => $args{prompt} // 'Select:',
            layout => 2,  # Single column
        }
    );

    return unless defined $choice;

    # Check for custom
    return undef if $choice =~ /^\[c\]/;

    # Extract index
    if ($choice =~ /^\[(\d+)\]/) {
        return $options->[$1];
    }
    return $options->[0];
}

=head3 choose_from

    my $selected = choose_from($options, %args);

Interactive selection using Term::Choose with keyboard navigation.
Users can use arrow keys, vim keys (hjkl), or Ctrl-F to search.

Options:
    prompt       - Header text to display
    inline_prompt - Prompt shown inline with selection
    layout       - 1 for columns (default), 2 for single column
    return_index - Return index instead of value (default: 0)
    mouse        - Enable mouse support (default: 0)

    my $title = choose_from(\@titles, prompt => "Select a title:");

=cut

sub choose_from {
    my ($options, %args) = @_;
    my $prompt_text = $args{prompt} // 'Select an option:';

    header($prompt_text) if $args{show_header};

    return choose(
        $options,
        {
            prompt => $args{inline_prompt} // '',
            layout => $args{layout} // 1,  # 1 = columns
            index  => $args{return_index} // 0,
            mouse  => $args{mouse} // 0,
            search => 1,  # Enable Ctrl-F search
        }
    );
}

=head3 choose_multiple

    my @selected = choose_multiple($options, %args);

Interactive multi-selection using Term::Choose. Users press SpaceBar
to mark items and Enter to confirm.

    my @features = choose_multiple(
        [qw(feature1 feature2 feature3)],
        prompt => "Select features to enable:",
        preselected => [0, 2],  # Pre-select first and third
    );

=cut

sub choose_multiple {
    my ($options, %args) = @_;
    my @selected = choose(
        $options,
        {
            prompt => $args{prompt} // 'Select items (Space to mark, Enter to confirm):',
            layout => 2,  # Single column for clarity
            mark   => $args{preselected} // [],
        }
    );
    return @selected;
}

=head2 Display

=head3 header

    header($text);

Display a styled header with border lines.

=cut

sub header {
    my ($text) = @_;
    my $line = "=" x 60;
    print colored(['bold', 'blue'], $line), "\n";
    print colored(['bold', 'white'], "  $text"), "\n";
    print colored(['bold', 'blue'], $line), "\n\n";
}

=head3 divider

    divider($char, $width);

Print a divider line. Defaults to '-' x 60.

=cut

sub divider {
    my ($char, $width) = @_;
    $char  //= '-';
    $width //= 60;
    print $char x $width, "\n";
}

=head3 status

    status($type, $message);

Print a status message with appropriate color and icon.
Types: success, error, warning, info

    status('success', "File saved");
    status('error', "Operation failed");
    status('warning', "Disk space low");
    status('info', "Processing 10 items");

=cut

sub status {
    my ($type, $message) = @_;
    my %colors = (
        success => 'green',
        error   => 'red',
        warning => 'yellow',
        info    => 'cyan',
    );
    my %icons = (
        success => "\x{2713}",  # Check mark
        error   => "\x{2717}",  # X mark
        warning => "\x{26A0}", # Warning sign
        info    => "\x{2139}",  # Info symbol
    );
    my $color = $colors{$type} // 'white';
    my $icon  = $icons{$type} // '*';
    print colored([$color], "$icon $message"), "\n";
}

=head2 Terminal Control

=head3 clear_line

    clear_line();

Clear the current line (useful for updating spinner messages).

=cut

sub clear_line {
    print "\r\033[K";
}

=head3 move_up

    move_up($n);

Move cursor up N lines.

=cut

sub move_up {
    my ($n) = @_;
    $n //= 1;
    print "\033[${n}A";
}

=head1 DEPENDENCIES

=over 4

=item * Term::ANSIColor (core module)

=item * Term::ReadLine (core module)

=item * Term::Choose

=item * Term::ReadKey (recommended, used by Term::Choose)

=item * Term::ProgressSpinner

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
