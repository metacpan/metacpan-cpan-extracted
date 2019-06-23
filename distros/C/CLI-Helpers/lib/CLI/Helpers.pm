package CLI::Helpers;
# ABSTRACT: Subroutines for making simple command line scripts
# RECOMMEND PREREQ: App::Nopaste

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Basename;
use Getopt::Long qw(:config pass_through);
use Module::Load qw(load);
use Ref::Util qw(is_ref is_arrayref is_hashref);
use Sys::Syslog qw(:standard);
use Term::ANSIColor 2.01 qw(color colored colorstrip);
use Term::ReadKey;
use Term::ReadLine;
use YAML;

our $VERSION = '1.4'; # VERSION

our $_OPTIONS_PARSED;
my  @ORIG_ARGS = @ARGV;

{ # Work-around for CPAN Smoke Test Failure
    # Details: http://perldoc.perl.org/5.8.9/Term/ReadLine.html#CAVEATS
    open( my $FH, '<', "/dev/tty" )
        or eval { sub Term::ReadLine::findConsole { ("&STDIN", "&STDERR") } };
    die $@ if $@;
    close $FH;
} # End Work-around


use Sub::Exporter -setup => {
    exports => [qw(
        output verbose debug debug_var override
        prompt confirm text_input menu pwprompt
    )],
    groups => {
        input  => [qw(prompt menu text_input confirm pwprompt)],
        output => [qw(output verbose debug debug_var)],
    }
};


my %opt = ();
if( !defined $_OPTIONS_PARSED ) {
    GetOptions(\%opt,
        'color!',
        'verbose|v+',
        'debug',
        'debug-class:s',
        'quiet',
        'data-file:s',
        'syslog!',
        'syslog-facility:s',
        'syslog-tag:s',
        'syslog-debug!',
        'tags:s',
        'nopaste',
        'nopaste-service:s@',
    );
    $_OPTIONS_PARSED = 1;
}

my $data_fh = undef;
if( exists $opt{'data-file'} ) {
    eval {
        open($data_fh, '>', $opt{'data-file'}) or die "data file unwritable: $!";
    };
    if( my $error = $@ ) {
        output({color=>'red',stderr=>1}, "Attempted to write to $opt{'data-file'} failed: $!");
    }
}

# Set defaults
my %DEF = (
    DEBUG           => $opt{debug}   || 0,
    DEBUG_CLASS     => $opt{'debug-class'} || 'main',
    VERBOSE         => $opt{verbose} || 0,
    COLOR           => $opt{color}   // git_color_check(),
    KV_FORMAT       => ': ',
    QUIET           => $opt{quiet}   || 0,
    SYSLOG          => $opt{syslog}  || 0,
    SYSLOG_TAG      => exists $opt{'syslog-tag'}      && length $opt{'syslog-tag'}      ? $opt{'syslog-tag'} : basename($0),
    SYSLOG_FACILITY => exists $opt{'syslog-facility'} && length $opt{'syslog-facility'} ? $opt{'syslog-facility'} : 'local0',
    SYSLOG_DEBUG    => $opt{'syslog-debug'}  || 0,
    TAGS            => $opt{tags} ? { map { $_ => 1 } split /,/, $opt{tags} } : undef,
    NOPASTE         => $opt{nopaste} || 0,
    NOPASTE_SERVICE => $opt{'nopaste-service'} || [ "Shadowcat" ],
);
debug({color=>'magenta'}, "CLI::Helpers Definitions");
debug_var(\%DEF);

# Setup the Syslog Subsystem
if( $DEF{SYSLOG} ) {
    my $syslog_ok = eval {
        openlog($DEF{SYSLOG_TAG}, 'ndelay,pid', $DEF{SYSLOG_FACILITY});
        1;
    };
    my $error = $@;
    if( !$syslog_ok ) {
        output({stderr=>1,color=>'red'}, "CLI::Helpers could not open syslog: $error");
        $DEF{SYSLOG}=0;
    }
}

my $TERM = undef;
my @STICKY = ();
my @NOPASTE = ();
my %TAGS    = ();

if( $DEF{NOPASTE} ) {
    eval {
        load 'App::Nopaste';
        1;
    } or do {
        $DEF{NOPASTE} = 0;
        output({stderr=>1,color=>'red',sticky=>1},
            'App::Nopaste is not installed, please cpanm App::Nopaste for --nopaste support',
        );
    };
}

# Allow some messages to be fired at the end the of program
END {
    # Show discovered tags
    if( keys %TAGS ) {
        output({color=>'cyan',stderr=>1},
            sprintf "# Tags discovered: %s",
                join(', ', map { "$_=$TAGS{$_}" } sort keys %TAGS)
        );
    }
    # Show Sticky Output
    if(@STICKY) {
        foreach my $args (@STICKY) {
            output(@{ $args });
        }
    }
    # Do the Nopaste
    if( @NOPASTE ) {
        my $command_string = join(" ", $0, @ORIG_ARGS);
        unshift @NOPASTE, "\$ $command_string";
        my %paste = (
            text => join("\n", @NOPASTE),
            summary => $command_string,
            desc    => $command_string,
            services => $DEF{NOPASTE_SERVICE},
        );
        debug_var(\%paste);
        output({color=>'cyan',stderr=>1}, "# NoPaste: "
            . App::Nopaste->nopaste(%paste)
        );
    }
    closelog() if $DEF{SYSLOG};
}


sub def { return exists $DEF{$_[0]} ? $DEF{$_[0]} : undef }


sub git_color_check {
    my @cmd = qw(git config --global --get color.ui);
    my($stdout,$stderr,$rc) = capture {
        system @cmd;
    };
    if( $rc != 0 ) {
        debug("git_color_check error: $stderr");
        return 0;
    }
    debug("git_color_check out: $stdout");
    if( $stdout =~ /auto/ || $stdout =~ /true/ ) {
        return 1;
    }
    return 0;
}


sub colorize {
    my ($color,$string) = @_;

   if( defined $color && $DEF{COLOR} ) {
        $string=colored([ $color ], $string);
    }
    return $string;
}


sub output {
    my $opts = is_hashref($_[0]) ? shift @_ : {};

    # Return unless we have something to work with;
    return unless @_;

    # Input/output Arrays
    my @input = map { my $x=$_; chomp($x) if defined $x; $x; } @_;
    my @output = ();

    # Determine the color
    my $color = exists $opts->{color} && defined $opts->{color} ? $opts->{color} : undef;

    # Determine indentation
    my $indent = exists $opts->{indent} ? " "x(2*$opts->{indent}) : '';

    # Determine if we're doing Key Value Pairs
    my $DO_KV = (scalar(@input) % 2 == 0 ) && (exists $opts->{kv} && $opts->{kv} == 1) ? 1 : 0;

    if( $DO_KV ) {
        while( @input ) {
            my $k = shift @input;
            # We only colorize the value
            my $v = shift @input;
            $v ||= $DEF{KV_FORMAT} eq ': ' ? '~' : '';
            push @output, join($DEF{KV_FORMAT}, $k, colorize($color,$v));
        }
    }
    else {
        @output = map { defined $color ? colorize($color, $_) : $_; } @input;
    }

    # If tagged, we only output if the tag is requested
    if( $DEF{TAGS} && exists $opts->{tag} ) {
        # Skip this altogether
        $TAGS{$opts->{tag}} ||= 0;
        $TAGS{$opts->{tag}}++;
        return unless $DEF{TAGS}->{$opts->{tag}};
    }
    # Out to the console
    if( !$DEF{QUIET} || (exists $opts->{IMPORTANT} && $opts->{IMPORTANT})) {
        my $out_handle = exists $opts->{stderr} && $opts->{stderr} ? \*STDERR : \*STDOUT;
        # Do clearing
        print $out_handle "\n"x$opts->{clear} if exists $opts->{clear};
        # Print output
        print $out_handle "${indent}$_\n" for @output;
    }

    # Handle data, which is raw
    if(defined $data_fh && exists $opts->{data} && $opts->{data}) {
        print $data_fh "$_\n" for @input;
    }
    elsif( $DEF{SYSLOG} && !(exists $opts->{no_syslog} && $opts->{no_syslog})) {
        my $level = exists $opts->{syslog_level} ? $opts->{syslog_level} :
                    exists $opts->{stderr}       ? 'err' :
                    'notice';

        # Warning for syslogging data file
        unshift @output, "CLI::Helpers logging a data section, use --data-file to suppress this in syslog."
            if exists $opts->{data} && $opts->{data};

        # Now syslog the message
        debug({no_syslog=>1,color=>'magenta'}, sprintf "[%s] Syslogging %d messages, with: %s", $level, scalar(@output), join(",", map { $_=>$opts->{$_} } keys %{ $opts }));
        for( @output ) {
            # One bad message means no more syslogging
            my $rc = $DEF{SYSLOG} = eval {
                syslog($level, colorstrip($_));
                1;
            };
            my $error = $@;
            if($rc != 1 ) {
                output({stderr=>1,color=>'red',no_syslog=>1}, "syslog() failed: $error");
            }
        }
    }

    # Sticky messages don't just go away
    if(exists $opts->{sticky}) {
        my %o = %{ $opts };  # Make a copy because we shifted this off @_
        # So this doesn't happen in the END block again
        delete $o{$_} for grep { exists $o{$_} } qw(sticky data);
        $o{no_syslog} = 1;
        push @STICKY, [ \%o, @input ];
    }
    if( $DEF{NOPASTE} ) {
        push @NOPASTE, @input;
    }
}


sub verbose {
    my $opts = is_hashref($_[0]) ? shift @_ : {};
    $opts->{level} = 1 unless exists $opts->{level};
    $opts->{syslog_level} = $opts->{level} > 1 ? 'debug' : 'info';
    my @msgs=@_;

    if( !$DEF{DEBUG} ) {
        return unless $DEF{VERBOSE} >= $opts->{level};
    }
    output( $opts, @msgs );
}


sub debug {
    my $opts = is_hashref($_[0]) ? shift @_ : {};
    my @msgs=@_;

    # Smarter handling of debug output
    return unless $DEF{DEBUG};

    # Check against caller class
    my $package = exists $opts->{_caller_package} ? $opts->{_caller_package} : (caller)[0];
    return unless lc $DEF{DEBUG_CLASS} eq 'all' || $package eq $DEF{DEBUG_CLASS};

    # Check if we really want to debug syslog data
    $opts->{syslog_level} = 'debug';
    $opts->{no_syslog} //= !$DEF{SYSLOG_DEBUG};

    # Output
    output( $opts, @msgs );
}


sub debug_var {
    my $opts = {
        clear           => 1,               # Meant for the screen
        no_syslog       => 1,               # Meant for the screen
        _caller_package => (caller)[0],     # Make sure this is set on entry
    };
    # Merge with options
    if( is_hashref($_[0]) && defined $_[1] && is_ref($_[1]) ) {
        my $ref = shift;
        foreach my $k (keys %{ $ref } ) {
            $opts->{$k} = $ref->{$k};
        };
    }
    debug($opts, Dump shift);
}


my %_allow_override = map { $_ => 1 } qw(debug verbose);
sub override {
    my ($var,$value) = @_;

    return unless exists $_allow_override{lc $var};

    my $def_var = uc $var;
    $DEF{$def_var} = $value;
}


my $_Confirm_Valid;
sub confirm {
    my ($question) = @_;

    # Initialize Globals
    $TERM ||= Term::ReadLine->new($0);
    $_Confirm_Valid ||= {qw(y 1 yes 1 n 0 no 0)};

    $question =~ s/\s*$/ [yN] /;
    my $answer = undef;
    until( defined $answer && exists $_Confirm_Valid->{$answer} ) {
        output({color=>'red',stderr=>1},"ERROR: must be one of 'y','n','yes','no'") if defined $answer;
        $answer = lc $TERM->readline($question);
    }
    return $_Confirm_Valid->{$answer};
}


sub text_input {
    my $question = shift;
    my %args = @_;

    # Prompt fixes
    chomp($question);
    my $terminator = $question =~ s/([^a-zA-Z0-9\)\]\}])\s*$// ? $1 : ':';
    if(exists $args{default}) {
        $question .= " (default=$args{default}) ";
    }
    $question .= "$terminator ";

    # Initialize Term
    $TERM ||= Term::ReadLine->new($0);

    # Make sure there's a space before the prompt
    $question =~ s/\s*$/ /;
    my $validate = exists $args{validate} ? $args{validate} : {};

    my $text;
    my $error = undef;
    until( defined $text && !defined $error ) {
        output({color=>'red',stderr=>1},"ERROR: $error") if defined $error;

        # Try to have the user answer the question
        $error=undef;
        if( exists $args{noecho} ) {
            # Disable all the Term ReadLine magic
            local $|=1;
            print STDOUT $question;
            ReadMode('noecho');
            $text = ReadLine();
            ReadMode('restore');
            print STDOUT "\n";
            chomp($text);
        }
        else {
            $text = $TERM->readline($question);
            $TERM->addhistory($text) if $text =~ /\S/;
        }

        # Check the default if the person just hit enter
        if( exists $args{default} && length($text) == 0 ) {
            return $args{default};
        }
        foreach my $v (keys %{$validate}) {
            local $_ = $text;
            if( $validate->{$v}->() > 0 ) {
                debug({indent=>1}," + Validated: $v");
                next;
            }
            $error = $v;
            last;
        }
    }
    return $text;
}


sub menu {
    my ($question,$opts) = @_;
    my %desc = ();

    # Initialize Term
    $TERM ||= Term::ReadLine->new($0);

    # Determine how to handle this list
    if( is_arrayref($opts) ) {
        %desc = map { $_ => $_ } @{ $opts };
    }
    elsif( is_hashref($opts) ) {
        %desc = %{ $opts };
    }
    my $OUT = $TERM->OUT || \*STDOUT;

    print $OUT "$question\n\n";
    my %ref = ();
    my $id  = 0;
    foreach my $key (sort keys %desc) {
        $ref{++$id} = $key;
    }

    my $choice;
    until( defined $choice && exists $ref{$choice} ) {
        output({color=>'red',stderr=>1},"ERROR: invalid selection") if defined $choice;
        foreach my $id (sort { $a <=> $b } keys %ref) {
            printf $OUT "    %d. %s\n", $id, $desc{$ref{$id}};
        }
        print $OUT "\n";
        $choice = $TERM->readline("Selection (1-$id): ");
        $TERM->addhistory($choice) if $choice =~ /\S/;
    }
    return $ref{$choice};
}


sub pwprompt {
    my ($prompt, %args) = @_;
    $prompt ||= "Password: ";
    my @more_validate;
    if (my $validate = $args{validate}){
        @more_validate = %$validate;
    }
    return text_input($prompt,
        noecho   => 1,
        validate => { "password length can't be zero." => sub { defined && length },
                      @more_validate,
                    },
    );
}


sub prompt {
    my ($prompt) = shift;
    my %args = @_;

    return confirm($prompt) if exists $args{yn};
    return menu($prompt, $args{menu}) if exists $args{menu};
    # Check for a password prompt
    if( lc($prompt) =~ /passw(or)?d/ ) {
        $args{noecho} = 1;
        $args{validate} ||= {};
        $args{validate}->{"password length can't be zero."} = sub { defined && length };
    }
    return text_input($prompt,%args);
}



# Return True
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Helpers - Subroutines for making simple command line scripts

=head1 VERSION

version 1.4

=head1 SYNOPSIS

Use this module to make writing intelligent command line scripts easier.

    #!/usr/bin/env perl
    use CLI::Helpers qw(:all);

    output({color=>'green'}, "Hello, World!");
    verbose({indent=>1,color=>'yellow'}, "Shiny, happy people!");
    verbose({level=>2,kv=>1,color=>'red'}, a => 1, b => 2);
    debug_var({ c => 3, d => 4});

    # Data
    output({data=>1}, join(',', qw(a b c d)));

    # Wait for confirmation
    die "ABORTING" unless confirm("Are you sure?");

    # Ask for a number
    my $integer = prompt "Enter an integer:", validate => { "not a number" => sub { /^\d+$/ } }

    # Ask for next move
    my %menu = (
        north => "Go north.",
        south => "Go south.",
    );
    my $dir = prompt "Where to, adventurous explorer?", menu => \%menu;

    # Ask for a favorite animal
    my $favorite = menu("Select your favorite animal:", [qw(dog cat pig fish otter)]);

Running as test.pl:

    $ ./test.pl
    Hello, World!
    a,b,c,d
    $ ./test.pl --verbose
    Hello, World!
      Shiny, Happy people!
    a,b,c,d
    $ ./test.pl -vv
    Hello, World!
      Shiny, Happy people!
      a: 1
      b: 2
    a,b,c,d
    $ ./test.pl --debug
    Hello, World!
      Shiny, Happy people!
      a: 1
      b: 2
    ---
    c: 3
    d: 4
    a,b,c,d

    $ ./test.pl --data-file=output.csv
    Hello, World!
    a,b,c,d
    $ cat output.csv
    a,b,c,d

Colors would be automatically enabled based on the user's ~/.gitconfig

=head1 OVERVIEW

This module provides a library of useful functions for constructing simple command
line interfaces.  It is able to extract information from the environment and your
~/.gitconfig to display data in a reasonable manner.

Using this module adds argument parsing using L<Getopt::Long> to your script.  It
enables pass-through, so you can still use your own argument parsing routines or
Getopt::Long in your script.

=head1 FUNCTIONS

=head2 def

Not exported by default, returns the setting defined.

=head2 git_color_check

Not exported by default.  Returns 1 if git is configured to output
using color of 0 if color is not enabled.

=head2 colorize( $color => 'message to be output' )

Not exported by default.  Checks if color is enabled and applies
the specified color to the string.

=head2 output( \%opts, @messages )

Exported.  Takes an optional hash reference and a list of
messages to be output.

=head2 verbose( \%opts, @messages )

Exported.  Takes an optional hash reference of formatting options.  Automatically
overrides the B<level> parameter to 1 if it's not set.

=head2 debug( \%opts, @messages )

Exported.  Takes an optional hash reference of formatting options.
Does not output anything unless DEBUG is set.

=head2 debug_var( \%opts, \%Variable )

Exported.  Takes an optional hash reference of formatting options.
Does not output anything unless DEBUG is set.

=head2 override( variable => 1 )

Exported.  Allows a block of code to override the debug or verbose level.  This
can be used during development to enable/disable the DEBUG/VERBOSE settings.

=head2 confirm("prompt")

Exported.  Creates a Yes/No Prompt which accepts y/n or yes/no case insensitively
but requires one or the other.

Returns 1 for 'yes' and 0 for 'no'

=head2 text_input("prompt", validate => { "too short" => sub { length $_ > 10 } })

Exported.  Provides a prompt to the user for input.  If validate is passed, it should be a hash reference
containing keys of error messages and values which are subroutines to validate the input available as $_.
If a validator fails, it's error message will be displayed, and the user will be re-prompted.

Valid options are:

=over 4

=item B<default>

Any string which will be used as the default value if the user just presses enter.

=item B<validate>

A hashref, keys are error messages, values are sub routines that return true when the value meets the criteria.

=item B<noecho>

Set as a key with any value and the prompt will turn off echoing responses as well as disabling all
ReadLine magic.  See also B<pwprompt>.

=back

Returns the text that has passed all validators.

=head2 menu("prompt", $ArrayOrHashRef)

Exported.  Used to create a menu of options from a list.  Can be either a hash or array reference
as the second argument.  In the case of a hash reference, the values will be displayed as options while
the selected key is returned.  In the case of an array reference, each element in the list is displayed
the selected element will be returned.

Returns selected element (HashRef -> Key, ArrayRef -> The Element)

=head2 pwprompt("Prompt", options )

Exported.  Synonym for text_input("Password: ", noecho => 1);  Also requires the password to be longer than 0 characters.

=head2 prompt("Prompt", options )

Exported.  Wrapper function with rudimentary mimicry of IO::Prompt(er).
Uses:

    # Mapping back to confirm();
    my $value = prompt "Are you sure?", yn => 1;

    # Mapping back to text_input();
    my $value = prompt "Enter something:";

    # With Validator
    my $value = prompt "Enter an integer:", validate => { "not a number" => sub { /^\d+$/ } }

    # Pass to menu();
    my $value = prompt "Select your favorite animal:", menu => [qw(dog cat pig fish otter)];

    # If you request a password, autodisable echo:
    my $passwd = prompt "Password: ";  # sets noecho => 1, disables ReadLine history.

See also: B<text_input>

=head1 EXPORT

This module uses L<Sub::Exporter> for flexible imports, the defaults provided by
:all are as follows.

=head2 Exported Functions

    output  ( \%options, @messages )
    verbose ( \%options, @messages )
    debug   ( \%options, @messages )
    debug_var ( \$var )
    override( option => $value )

    menu       ( "Question", \%Options or \@Options )
    text_input ( "Question", validate => { "error message" => sub { length $_[0] } } )
    confirm    ( "Question" )

    prompt()    Wrapper which mimics IO::Prompt a bit
    pwprompt()  Wrapper to get sensitive data

=head1 ARGS

From CLI::Helpers:

    --data-file         Path to a file to write lines tagged with 'data => 1'
    --tags              A comma separated list of tags to display
    --color             Boolean, enable/disable color, default use git settings
    --verbose           Incremental, increase verbosity (Alias is -v)
    --debug             Show developer output
    --debug-class       Show debug messages originating from a specific package, default: main
    --quiet             Show no output (for cron)
    --syslog            Generate messages to syslog as well
    --syslog-facility   Default "local0"
    --syslog-tag        The program name, default is the script name
    --syslog-debug      Enable debug messages to syslog if in use, default false
    --nopaste           Use App::Nopaste to paste output to configured paste service
    --nopaste-service   Named App::Nopaste service to target, defaults to Shadowcat

=head1 NOPASTE

This is optional and will only work if you have L<App::Nopaste> installed.  If
you just specify C<--nopaste>, any output that would be displayed to the screen
is submitted to the L<App::Nopaste::Service::Shadowcat> paste bin.  This
paste service is pretty simple, but works reliably.

During the C<END> block, the output is submitted and the URL of the paste is
returned to the user.

=head1 OUTPUT OPTIONS

Every output function takes an optional HASH reference containing options for
that output.  The hash may contain the following options:

=over 4

=item B<tag>

Add a keyword to tag output with.  The user may then specify C<--tags
keyword1,keyword2> to only view output at the appropriate level.  This option
will affect C<data-file> and C<syslog> output.  The output filter requires both
the presence of the C<tag> in the output options B<and> the user to specify
C<--tags> on the command line.

Consider a script, C<status.pl>:

    output("System Status: Normal")
    output({tag=>'foo'}, "Component Foo: OK");
    output({tag=>'bar'}, "Component Bar: OK");

If an operator runs:

    $ status.pl
    System Status: Normal
    Component Foo: OK
    Component Bar: OK

    $ status.pl --tags bar
    System Status: Normal
    Component Bar: OK

    $ status.pl --tags foo
    System Status: Normal
    Component Foo: OK

This could be helpful for selecting one or more pertinent tags to display.

=item B<sticky>

Any lines tagged with 'sticky' will be replayed at the end program's end.  This
is to allow a developer to ensure message are seen at the termination of the program.

=item B<color>

String. Using Term::ANSIColor for output, use the color designated, i.e.:

    red,blue,green,yellow,cyan,magenta,white,black, etc..

=item B<level>

Integer. For verbose output, this is basically the number of -v's necessary to see
this output.

=item B<syslog_level>

String.  Can be any valid syslog_level as a string: debug, info, notice, warning, err, crit,
alert, emerg.

=item B<no_syslog>

Bool.  Even if the user specifies --syslog, these lines will not go to the syslog destination.
alert, emerg.

=item B<IMPORTANT>

Bool. Even if --quiet is specified, output this message.  Use sparingly, and yes,
it is case sensitive.  You need to yell at it for it to yell at your users.

=item B<stderr>

Bool. Use STDERR for this message instead of STDOUT.  The advantage to using this is the
"quiet" option will silence these messages as well.

=item B<indent>

Integer.  This will indent by 2 times the specified integer the next string.  Useful
for creating nested output in a script.

=item B<clear>

Integer.  The number of newlines before this output.

=item B<kv>

Bool.  The array of messages is actually a key/value pair, this implements special coloring and
expects the number of messages to be even.

    output(qw(a 1 b 2));
    # a
    # 1
    # b
    # 2

Using kv, the output will look like this:

    output({kv=>1}, qw(a 1 b 2));
    # a: 1
    # b: 2
    #

=item B<data>

Bool.  Lines tagged with "data => 1" will be output to the data-file if a user specifies it.  This allows
you to provide header/footers and inline context for the main CLI, but output just the data to a file for
piping elsewhere.

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CONTRIBUTORS

=for stopwords Kang-min Liu Kevin M. Goess Mohammad S Anwar

=over 4

=item *

Kang-min Liu <gugod@gugod.org>

=item *

Kevin M. Goess <kgoess@craigslist.org>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/CLI-Helpers>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-Helpers>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/CLI-Helpers>

=cut
