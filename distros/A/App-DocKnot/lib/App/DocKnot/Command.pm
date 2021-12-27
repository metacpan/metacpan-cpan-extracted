# Dispatch code for the DocKnot application.
#
# DocKnot provides various commands for generating documentation, web pages,
# and software releases.  This module provides command-line parsing and
# dispatch of commands to the various App::DocKnot modules.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Command 6.00;

use 5.024;
use autodie;
use warnings;

use App::DocKnot::Dist;
use App::DocKnot::Generate;
use App::DocKnot::Spin;
use App::DocKnot::Spin::RSS;
use App::DocKnot::Spin::Thread;
use App::DocKnot::Update;
use Getopt::Long;
use Pod::Usage qw(pod2usage);

# Defines the subcommands, their options, and the module and method that
# implements them.  The keys are the names of the commands.  Each value is a
# hash with one or more of the following keys:
#
# code
#     A reference to a function to call to implement this command.  If set,
#     overrides method and module.  The function will be passed a reference to
#     the hash resulting from option parsing as its first argument and any
#     other command-line arguments as its remaining arguments.
#
# maximum
#     The maximum number of positional arguments this command takes.
#
# method
#     The name of the method to run to implement this command.  It is passed
#     as arguments any remaining command-line arguments after option parsing.
#
# minimum
#     The minimum number of positional arguments this command takes.
#
# module
#     The name of the module that implements this command.  Its constructor
#     (which must be named new) will be passed as its sole argument a
#     reference to the hash containing the results of parsing any options.
#
# options
#     A reference to an array of Getopt::Long option specifications defining
#     the arguments that can be passed to this subcommand.
#
# required
#     A reference to an array of required option names (the part before any |
#     in the option specification for that option).  If any of these options
#     are not set, an error will be thrown.
our %COMMANDS = (
    dist => {
        method => 'make_distribution',
        module => 'App::DocKnot::Dist',
        options => ['distdir|d=s', 'metadata|m=s', 'pgp-key|p=s'],
        maximum => 0,
    },
    generate => {
        method => 'generate_output',
        module => 'App::DocKnot::Generate',
        options => ['metadata|m=s', 'width|w=i'],
        maximum => 2,
        minimum => 1,
    },
    'generate-all' => {
        method => 'generate_all',
        module => 'App::DocKnot::Generate',
        options => ['metadata|m=s', 'width|w=i'],
        maximum => 0,
    },
    spin => {
        method => 'spin',
        module => 'App::DocKnot::Spin',
        options => ['delete|d', 'exclude|e=s@', 'style-url|s=s'],
        minimum => 2,
        maximum => 2,
    },
    'spin-rss' => {
        method => 'generate',
        module => 'App::DocKnot::Spin::RSS',
        options => ['base|b=s'],
        minimum => 1,
        maximum => 1,
    },
    'spin-thread' => {
        method => 'spin_thread_file',
        module => 'App::DocKnot::Spin::Thread',
        options => ['style-url|s=s'],
        maximum => 2,
    },
    update => {
        method => 'update',
        module => 'App::DocKnot::Update',
        options => ['metadata|m=s', 'output|o=s'],
        maximum => 0,
    },
);

##############################################################################
# Option parsing
##############################################################################

# Parse command-line options and do any required error handling.
#
# $command     - The command being run or undef for top-level options
# $options_ref - A reference to the options specification
# @args        - The arguments to the command
#
# Returns: A list composed of a reference to a hash of options and values,
#          followed by a reference to the remaining arguments after options
#          have been extracted
#  Throws: A text error message if the options are invalid
sub _parse_options {
    my ($self, $command, $options_ref, @args) = @_;

    # Use the object-oriented syntax to isolate configuration options from the
    # rest of the program.
    my $parser = Getopt::Long::Parser->new;
    $parser->configure(qw(bundling no_ignore_case require_order));

    # Parse the options and capture any errors, turning them into exceptions.
    # The first letter of the Getopt::Long warning message will be capitalized
    # but we want it to be lowercase to follow our error message standard.
    my %opts;
    {
        my $error = 'option parsing failed';
        local $SIG{__WARN__} = sub { ($error) = @_ };
        if (!$parser->getoptionsfromarray(\@args, \%opts, $options_ref->@*)) {
            $error =~ s{ \n+ \z }{}xms;
            $error =~ s{ \A (\w) }{ lc($1) }xmse;
            if ($command) {
                die "$0 $command: $error\n";
            } else {
                die "$0: $error\n";
            }
        }
    }

    # Success.  Return the options and the remaining arguments.
    return (\%opts, \@args);
}

# Parse command-line options for a given command.
#
# $command - The command being run
# @args    - The arguments to the command
#
# Returns: A list composed of a reference to a hash of options and values,
#          followed by a reference to the remaining arguments after options
#          have been extracted
#  Throws: A text error message if the options are invalid
sub _parse_command {
    my ($self, $command, @args) = @_;
    my $options_ref = $COMMANDS{$command}{options};
    return $self->_parse_options($command, $options_ref, @args);
}

##############################################################################
# Error handling
##############################################################################

# Reformat an error message (from warn or die) to prepend the command run and
# to strip the file and line information from Perl.
#
# $command - Invoked command
# $error   - Error to reformat
#
# Return: Reformatted error suitable for passing to warn or die, with no
#         trailing newline (the caller should add it)
sub _reformat_error {
    my ($self, $command, $error) = @_;
    chomp($error);
    $error =~ s{ \s+ at \s+ \S+ \s+ line \s+ \d+ [.]? \z }{}xms;
    if ($error =~ m{ \S+ : \d+ : \s+ \S }xms) {
        return "$0 $command:$error";
    } else {
        return "$0 $command: $error";
    }
}

##############################################################################
# Public interface
##############################################################################

# Create a new App::DocKnot::Command object.
#
# Returns: Newly created object
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    return $self;
}

# Parse command-line options to determine which command to run, and then
# dispatch that command.
#
# @args - Command-line arguments (optional, default: @ARGV)
#
# Returns: undef
#  Throws: A text error message for invalid arguments
sub run {
    my ($self, @args) = @_;
    if (!@args) {
        @args = @ARGV;
    }

    # Parse the initial options and extract the subcommand to run, preserving
    # any options after the subcommand.
    my $spec = ['help|h'];
    my ($opts_ref, $args_ref) = $self->_parse_options(undef, $spec, @args);
    if ($opts_ref->{help}) {
        pod2usage(0);
    }
    if (!$args_ref->@*) {
        die "$0: no subcommand given\n";
    }
    my $command = shift($args_ref->@*);
    if (!$COMMANDS{$command}) {
        die "$0: unknown command $command\n";
    }

    # Parse the arguments for the command and check for required arguments.
    ($opts_ref, $args_ref) = $self->_parse_command($command, $args_ref->@*);
    if (exists($COMMANDS{$command}{required})) {
        for my $required ($COMMANDS{$command}{required}->@*) {
            if (!exists($opts_ref->{$required})) {
                die "$0 $command: missing required option --$required\n";
            }
        }
    }

    # Check that we have the correct number of remaining arguments.
    if (exists($COMMANDS{$command}{maximum})) {
        if (scalar($args_ref->@*) > $COMMANDS{$command}{maximum}) {
            die "$0 $command: too many arguments\n";
        }
    }
    if (exists($COMMANDS{$command}{minimum})) {
        if (scalar($args_ref->@*) < $COMMANDS{$command}{minimum}) {
            die "$0 $command: too few arguments\n";
        }
    }

    # Dispatch the command and turn exceptions into error messages.  Also
    # capture warnings and perform the same transformation on those.
    local $SIG{__WARN__} = sub {
        my ($error) = @_;
        $error = $self->_reformat_error($command, $error);
        warn "$error\n";
    };
    eval {
        my $object = $COMMANDS{$command}{module}->new($opts_ref);
        my $method = $COMMANDS{$command}{method};
        $object->$method($args_ref->@*);
    };
    if ($@) {
        my $error = $self->_reformat_error($command, $@);
        die "$error\n";
    }
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot docknot MERCHANTABILITY NONINFRINGEMENT sublicense Kwalify
IO-Compress-Lzma TimeDate

=head1 NAME

App::DocKnot::Command - Run DocKnot commands

=head1 SYNOPSIS

    my $docknot = App::DocKnot::Command->new();
    $docknot->run();

=head1 REQUIREMENTS

Perl 5.24 or later and the modules Date::Language, Date::Parse (both part of
TimeDate), File::BaseDir, File::ShareDir, Git::Repository, Image::Size,
IO::Compress::Xz (part of IO-Compress-Lzma), IO::Uncompress::Gunzip (part of
IO-Compress), IPC::Run, IPC::System::Simple, JSON::MaybeXS, Kwalify,
List::SomeUtils, Path::Tiny, Perl6::Slurp, Template (part of Template
Toolkit), and YAML::XS, all of which are available from CPAN.

=head1 DESCRIPTION

The App::DocKnot::Command module implements the B<docknot> command-line
interface to all of the functions of DocKnot.  It is an implementation detail
of the B<docknot> command-line tool and is normally only called by that
program.

For full documentation, see L<docknot(1)>.

=head1 CLASS METHODS

=over 4

=item new()

Create a new App::DocKnot::Command object.

=back

=head1 INSTANCE METHODS

=over 4

=item run([ARGS])

Run the DocKnot action specified by ARGS, which are parsed as command-line
arguments to B<docknot>.  If ARGS is not given or is empty, C<@ARGV> will be
parsed instead.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018-2021 Russ Allbery <rra@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<docknot(1)>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
