package App::Colorist::Colorizer;
$App::Colorist::Colorizer::VERSION = '0.150460';
use Moose;

use Carp;
use IO::Handle;
use IO::Select;
use POSIX;
use Readonly;
use Scalar::Util qw( refaddr );
use YAML;

# ABSTRACT: the brain behind App::Colorist


has configuration => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has ruleset => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'rules',
);


has colorset => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'colors',
);


has include => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    default     => sub { [] },
    handles     => {
        'include_paths' => 'elements',
    },
);


has debug => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);


has inputs => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy_build  => 1,
    traits      => [ 'Array' ],
    handles     => {
        all_inputs => 'elements',
    },
);

sub _build_inputs { [ \*ARGV ] }


has selected_inputs => (
    is          => 'ro',
    isa         => 'IO::Select',
    lazy_build  => 1,
);

sub _build_selected_inputs {
    my $self = shift;
    my $s = IO::Select->new;
    $s->add($self->all_inputs);
    return $s;
}


has input_buffers => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy_build  => 1,
    traits      => [ 'Hash' ],
    handles     => {
        input_buffer_keys => 'keys',
        get_input_buffer  => 'get',
        set_input_buffer  => 'set',
    },
);

sub _build_input_buffers { +{} }


has output => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_output { \*STDOUT }


has search_path => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy_build  => 1,
    traits      => [ 'Array' ],
    handles     => {
        all_search_paths => 'elements',
        first_path_that  => 'first',
    },
);

sub _build_search_path {
    my $self = shift;

    return [
        $self->include_paths,
        (grep { $_ } split /:/, ($ENV{COLORIST_CONFIG}||'')),
        "$ENV{HOME}/.colorist",
        '/etc/colorist',
    ];
}


has ruleset_file => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_ruleset_file {
    my $self = shift;

    my $config  = $self->configuration;
    my $ruleset = $self->ruleset;

    my $path = $self->first_path_that(sub {
        return 0 unless -d "$_/$config";
        return 1 if -f "$_/$config/$ruleset.pl";
        return 0;
    });

    croak(qq[Unable to locate rules "$ruleset" in paths: ], join(' ', $self->all_search_paths))
        unless defined $path;

    return "$path/$config/$ruleset.pl";
}


has colorset_file => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_colorset_file {
    my $self = shift;

    my $config   = $self->configuration;
    my $colorset = $self->colorset;

    my $path = $self->first_path_that(sub {
        return 0 unless -d "$_/$config";
        return 1 if -f "$_/$config/$colorset.yml";
        return 0;
    });

    croak(qq[Unable to locate colors "$colorset" in paths: ], join(' ', $self->all_search_paths))
        unless defined $path;

    return "$path/$config/$colorset.yml";
}


has colors_mtime => (
    is          => 'rw',
    isa         => 'Int',
    default     => 0,
);


has colors => (
    is          => 'rw',
    isa         => 'HashRef',
    trigger     => sub { 
        my $self = shift;
        $self->colors_mtime( (stat $self->colorset_file)[9] ) 
    },
);


has rules_mtime => (
    is          => 'rw',
    isa         => 'Int',
    default     => 0,
);


has rules => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    trigger     => sub { 
        my $self = shift;
        $self->rules_mtime( (stat $self->ruleset_file)[9] ) 
    },
    handles     => {
        rule_pairs => [ 'natatime', 2 ],
    },
);


sub load_colorset_file {
    my $self = shift;
    return YAML::LoadFile($self->colorset_file);
}


sub refresh_colorset_file {
    my $self = shift;
    if ( (stat $self->colorset_file)[9] > $self->colors_mtime ) {
        $self->colors( $self->load_colorset_file );
    }
}


sub load_ruleset_file {
    my $self = shift;

    my $ruleset_file = $self->ruleset_file;
    my $rules;

    {
        package 
            ruleset;
        use App::Colorist::Ruleset;
        $rules = do "$ruleset_file"
            or Carp::croak(qq[Failed to read rule set "$ruleset_file": $@]);
        push @$rules, qr{.*}, [ 'DEFAULT' ];
    }

    return $rules;
}


sub refresh_ruleset_file {
    my $self = shift;
    if ( (stat $self->ruleset_file)[9] > $self->rules_mtime ) {
        $self->rules( $self->load_ruleset_file );
    }
}

Readonly my %color_names => (
    black  => 0, gray    => 8,
    maroon => 1, red     => 9,
    green  => 2, lime    => 10,
    olive  => 3, yellow  => 11,
    navy   => 4, blue    => 12,
    purple => 5, fuschia => 13,
    teal   => 6, aqua    => 14,
    silver => 7, white   => 15,
    map { ($_ => $_) } (0 .. 255),
);


sub print_reset_line { 
    my $self = shift;
    my $fh = $self->output;

    if ($self->debug) {
        $fh->print("{reset}");
        return;
    }

    $fh->print("\e[0m");
}


sub get_fg { 
    my ($self, $fg) = @_;

    return '' unless defined $fg; 
    if ($self->debug) {
        return "{$fg}";
    }
    else {
        return sprintf "\e[38;5;%03dm", $fg;
    }
}


sub get_bg { 
    my ($self, $bg) = @_;

    return '' unless defined $bg; 

    if ($self->debug) {
        return "{$bg}";
    }
    else {
        return sprintf "\e[48;5;%03dm", $bg;
    }
}


sub gray { 
    my ($self, $offset) = @_;
    return 232 + $offset;
}


sub rgb { 
    my ($self, $r, $g, $b) = @_;
    return 16 + $r*36 + $g*6 + $b;
}


sub eval_color {
    my ($self, $c) = @_;

    return !defined($c) ? undef
         : !ref($c)     ? $color_names{$c}
         : @{$c} == 1   ? gray(@{$c})
         : @{$c} == 3   ? rgb(@{$c})
         :                croak("unknown color type");
}


sub fg { 
    my ($self, $c) = @_;
    $self->get_fg($self->eval_color($c));
}


sub bg($) { 
    my ($self, $c) = @_;
    $self->get_bg($self->eval_color($c));
}


sub c {
    my ($self, $n) = @_;

    my $c = $self->colors->{$n};
    return unless defined $c;

    my ($fg, $bg);
    if (ref $c eq 'HASH') {
        $fg = $c->{fg};
        $bg = $c->{bg};
    }
    else {
        $fg = $c;
    }

    return $self->fg($fg).$self->bg($bg);
}


sub run {
    my $self = shift;

    $self->loop_and_colorize;
}


sub _split {
    my ($line) = @_;
    return split /^/, $line, 2;
}

sub readline {
    my ($self) = @_;

    my $s = $self->selected_inputs;

    # Empty pending buffers first
    for my $key ($self->input_buffer_keys) {
        my $buffer = $self->get_input_buffer($key);

        if (defined $buffer && $buffer =~ /\n/) {
            my ($first_line, $rest) = _split($buffer);
            $self->set_input_buffer($key, $rest);
            return $first_line;
        }
    }

    # We will keep trying this until we get a full line
    while (1) {

        # Quit if we've run out of handles
        return unless $s->count > 0;

        # Otherwise, block until we have something to read
        my @ready = $s->can_read;
        for my $fh (@ready) {
            $fh->blocking(0);

            # Start with the existing buffer
            my $line = $self->get_input_buffer(refaddr($fh));
            $line = '' unless defined $line;

            # Read it until we run out of input or until we hit at least one newline
            my ($eof, $buffer);
            READ: while (!defined $eof || ($eof != 0 && $line !~ /\n/)) {
                $eof = sysread($fh, $buffer, 1024);
                if (not defined $eof) {
                    if ($! == POSIX::EAGAIN) {
                        select undef, undef, undef, 0.1;
                        next READ;
                    }
                    else {
                        croak("Error while reading handle: $!");
                    }
                }
                $line .= $buffer;
            }

            $s->remove($fh) if $eof == 0;

            # If we got a newline, return the first line and buffer the rest
            if ($line =~ /\n/) {
                my ($first_line, $rest) = _split($line);
                $self->set_input_buffer(refaddr($fh), $rest);
                return $first_line;
            }

            # Otherwise, we got nothing, buffer all of it and keep going
            else {
                $self->set_input_buffer(refaddr($fh), $line);
            }

            # Guess we will try the next ready file handle
        }

        # Guess we'll go around again and wait for ready buffers again
    }
}


sub loop_and_colorize {
    my $self = shift;

    while (my $line = $self->readline) {
        $self->refresh_ruleset_file;
        $self->refresh_colorset_file;

        $self->colorize($line);
    }
}


sub colorize {
    my ($self, $line) = @_;
    local $_ = $line;

    my $fh = $self->output;

    my $iter = $self->rule_pairs;
    RULE: while (my ($rule, $names) = $iter->()) {

        if (/^$rule$/) {

            # This sort is a little complex, so here's the explanation:
            #
            # We want to keep the parenthetical nesting in the correct order.
            # This is easy when the parenthesis is separated by index. This is
            # not easy otherwise. Here are some sample cases to explain:
            #
            #     a(b)c - we can sort just by string position
            #     a(b(c - DITTO
            #     a)b)c - DITTO
            #     a)b(c - DITTO
            #
            # Hard cases:
            #
            #      11  <--- indexes in @- and @+
            #     a()b - sorting by group index order, ascending works
            #      XY  <--- starting parenthesis = X, ending parenthesis = Y
            # 
            #      12  <--- indexes in @- and @+
            #     a((b - we need to sort by group index order, ascending
            #      XX  <--- starting parenthesis = X, ending parenthesis = Y
            #
            #  *   21  <--- indexes in @- and @+
            #  *  a))b - we need to sort by group index order, descending
            #  *   YY  <--- starting parenthesis = X, ending parenthesis = Y
            #
            #      12  <--- indexes in @- and @+
            #     a)(b - we need to sort by group index order, ascending
            #      YX  <--- starting parenthesis = X, ending parenthesis = Y

            my @pos = sort { 
                    $a->[0] <=> $b->[0] # match index first
                || ($a->[1] eq 'Y' and $b->[1] eq 'Y' ? $b->[2] <=> $a->[2] # X? name index (asc)
                    :                                    $a->[2] <=> $b->[2]) # Y? XY? YX? index (desc)
            } (
                (map { [ ($-[$_] // 0), 'X', $_ ] } 0 .. $#- ),
                (map { [ ($+[$_] // 0), 'Y', $_ ] } 0 .. $#+ ),
            );
            @pos = ([ 0, 'X', undef ], @pos, [ length, 'Y', undef ]);
            #warn YAML::Dump(\@pos);

            my $offset = 0;
            my @stack;
            for my $pos (@pos) {
                my ($i, $d, $n) = @$pos;

                my $color;
                if ($d eq 'X') {
                    if (defined $n) {
                        $color = $self->c($names->[$n]);
                    }
                    else {
                        $color = $self->c('DEFAULT');
                    }

                    push @stack, $color;
                }
                else {
                    pop @stack;
                    if (@stack) {
                        $color = $stack[-1];
                    }
                    else {
                        $color = $self->c('DEFAULT');
                    }
                }

                if (defined $color) {
                    substr($_, $i + $offset, 0) = $color;
                    $offset += length $color;
                }
            }

            last RULE;
        }
    }

    $fh->print($_);
    $self->print_reset_line;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Colorist::Colorizer - the brain behind App::Colorist

=head1 VERSION

version 0.150460

=head1 SYNOPSIS

  my $colorizer = App::Colorist::Colorizer->enw(
      commandset => 'mycommand',
  );
  $colorizer->run;

=head1 DESCRIPTION

This is primarily engineered as a separate module to make testing easier. However, if you want to embed a colorizer in some other program for some reason or you want to extend colorizer, this provides the tools for that as well. This is why I decided to provide documentation for this module here.

If you do provide extensions, I would love to see them. Patches are welcome.

=head1 ATTRIBUTES

=head2 configuration

This is the name of the master configuration to use. This is usually the name of the command whose output you are colorizing. Each configuration must contain at least one ruleset and one colorset configuration. See L<App::Colorist/CONFIGURATION> for details on how this is used to locate the configuration files.

=head2 ruleset

This is the name of the rule set to use. See L<App::Colorist/CONFIGURATION> for how rule sets are defined and located.

=head2 colorset

This is the name of the color set to use. See L<App::Colorist/CONFIGURATION> for how color sets are defined and located.

=head2 include

This is an array of extra include paths to search when looking for colorist configuration files.

=head2 debug

This is mostly useful for testing the app itself. When set to a true value, the colors are not output but a numeric representation like "{12}" is output instead.

=head2 inputs

This is an array of file handles to use for input. A builder lazily sets this to an array containing only the C<ARGV> file handle by default. If more than one file handle is passed, this will capture output of all file handles and display from each as they come.

=head2 selected_inputs

This is an L<IO::Select> built from the list of input file handles in L</inputs>.

=head2 input_buffers

This is an array of strings used as input buffers. This is used with the non-blocking I/O code to store any partially read lines encountered.

=head2 output

This is the fil ehandle to use for output. A builder lazily sets this to C<STDOUT> by default.

=head2 search_path

This contains the full search path. You do not normally want to set this yourself, but use L</include> instead. It is lazily instantiated to includ the values set in L</include>, the value of the C<COLORIST_CONFIG> environment variable, followed by F<~/.colorist> and finally F</etc/colorist>.

=head2 ruleset_file

This is set to the name of the actual ruleset file found by searching L</search_paths> and L</ruleset>.

=head2 colorset_file

This is the actual colorset file found by searching L</search_paths> for C<colorset>.

=head2 colors_mtime

When the colorset file is loaded, this mtime is set to the current mtime of the file. Every time a line is colored it checks to see if the colorset file has changed and will reload it automatically if it has.

=head2 colors

This is the actual colorset configuration. It's a set of keys naming the various color names defined in the ruleset and the values are the color definitions. See L<App::Colorist/CONFIGURATION> for details.

=head2 rules_mtime

Whenever the rules are loaded, this mtime is recorded. If the file changes, the rules are reloaded.

=head2 rules

This contains the actual rules. This is an array where the even number indices point to a regular expression used to match lines and group submatches. The odd indices contain an array of names matching the overall match and the group matches, which are looked up in the L</colors> configuration. See L<App::Colorist/CONFIGURATION> for details.

=head1 METHODS

=head2 load_colorset_file

Loads the colorset configuration using L<YAML>.

=head2 refresh_colorset_file

Checks to see if the L</colors> need to be reloaded and calls L</load_colorset_file> if they do.

=head2 load_ruleset_file

Reads in the ruleset configuration using a Perl C<do>.

=head2 refresh_ruleset_file

Checks to see if the ruleset file has changed since it's last load and calls L<load_ruleset_file> to reload the configuration if it has.

=head2 print_reset_line

Prints the escape code to reset everything to the terminal default.

=head2 get_fg

  my $code = $c->get_fg(10);

Returns the escape code required to change the foreground color to the given color number.

=head2 get_bg

  my $code = $self->get_bg(10);

Returns the escape code that will change the background color to the given color code.

=head2 gray

  my $number = $c->gray(10);

Given a number identifying the desired shade of gray, returns that color number. Only works on terminals supporting 256 colors.

=head2 rgb

  my $number = $c->rgb(1, 3, 4);

Given 3 numbers identifying the desired RGB color cube, returns that color number. Only works on terminals supporting 256 colors.

=head2 eval_color

  my $number = $c->eval_color('blue');
  my $number = $c->eval_color(10);
  my $number = $c->eval_color([ 8 ]);
  my $number = $c->eval_color([ 1, 2, 3 ]);

Given one of the possible color configuration types from the color set configuration, returns a color number for it.

=head2 fg

  my $code = $c->fg('blue');
  my $code = $c->fg(10);
  my $code = $c->fg([ 8 ]);
  my $code = $c->fg([ 1, 2, 3 ]);

Returns the escape code for changing the foreground color to the given color identifier.

=head2 bg

  my $code = $c->bg('blue');
  my $code = $c->bg(10);
  my $code = $c->bg([ 8 ]);
  my $code = $c->bg([ 1, 2, 3 ]);

Returns the escape code for changing the background color to the given color identifier.

=head2 c

  my $code = $c->c('rufus');

Given the name of a color defined in the colorset, returns the escape codes defined for that color to change the background and foreground as configured.

=head2 run

Runs the colorization process to colorize input and send that to the output.

=head2 readline

Given an L<IO::Select> object, returns the first line it finds from the selected
file handles. This handles all buffering on the file handles and blocks until a
complete line is available. It returns only the first line that comes available.
It makes no guarantees about the order the file handles will be read or
processed. It does try to conserve memory and keep the buffers relatively small.

=head2 loop_and_colorize

Reads each line of input, reloads the ruleset and colorset configuration if they have changed, and calls L</colorize> to add color to the input and send it to the output.

=head2 colorize

  $c->colorize('some input');

Given a line of input, this method matches the ruleset rules agains the line until it finds a match. It then applies all the colors for the line and groups defined in the colorset and outputs that line to the output file handle.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
