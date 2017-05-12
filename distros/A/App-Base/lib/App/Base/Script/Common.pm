package App::Base::Script::Common;
use strict;
use warnings;
use 5.010;
use Moose::Role;

our $VERSION = '0.07';    ## VERSION

=head1 NAME

App::Base::Script::Common - Behaviors common to App::Base::Script and App::Base::Daemon

=head1 DESCRIPTION

App::Base::Script::Common provides infrastructure that is common to the
App::Base::Script and App::Base::Daemon classes, including options parsing.

=cut

use App::Base::Script::Option;

use Cwd qw( abs_path );
use Getopt::Long;
use IO::Handle;
use List::Util qw( max );
use Path::Tiny;
use POSIX qw( strftime );
use Text::Reform qw( form break_wrap );
use Try::Tiny;

use MooseX::Types::Moose qw( Str Bool );

has 'return_value' => (
    is      => 'rw',
    default => 0
);

=head1 REQUIRED SUBCLASS METHODS

=head2 documentation

Returns a scalar (string) containing the documentation portion
of the script's usage statement.

=cut

requires 'documentation';    # Seriously, it does.

# For our own subclasses like App::Base::Script and App::Base::Daemon

=head2 __run

For INTERNAL USE ONLY: Used by subclasses such as App::Base::Script and
App::Base::Daemon to redefine dispatch rules to their own required
subclass methods such as script_run() and daemon_run().

=cut

requires '__run';

=head2 error

All App::Base::Script::Common-implementing classes must have an
error() method that handles exceptional cases which also
require a shutdown of the running script/daemon/whatever.

=cut

requires 'error';

=head1 OPTIONAL SUBCLASS METHODS

=head2 options

Concrete subclasses can specify their own options list by defining a method
called options() which returns an arrayref of hashes with the parameters
required to create L<App::Base::Script::Option> objects. Alternatively, your
script/daemon can simply get by with the standard --help option provided by its
role.

=cut

sub options {
    my $self = shift;
    return [];
}

=head1 ATTRIBUTES

=head2 _option_values

The (parsed) option values, including defaults values if none were
specified, for all of the options declared by $self. This accessor
should not be called directly; use getOption() instead.

=cut

has '_option_values' => (
    is  => 'rw',
    isa => 'HashRef',
);

=head2 orig_args

An arrayref of arguments as they existed prior to option parsing.

=cut

has 'orig_args' => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

=head2 parsed_args

An arrayref of the arguments which remained after option parsing.

=cut

has 'parsed_args' => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

=head2 script_name

The name of the running script, computed from $0.

=cut

has 'script_name' => (
    is      => 'ro',
    default => sub { path($0)->basename; },
);

=head1 METHODS

=head2 BUILDARGS

Combines the results of base_options() and options() and then parses the
command-line arguments of the script. Exits with a readable error message
if the script was invoked in a nonsensical or invalid manner.

=cut

sub BUILDARGS {
    my $class   = shift;
    my $arg_ref = shift;

    ## no critic (RequireLocalizedPunctuationVars)
    $ENV{APP_BASE_SCRIPT_EXE} = abs_path($0);
    $arg_ref->{orig_args} = [@ARGV];

    my $results = $class->_parse_arguments(\@ARGV);
    if ($results->{parse_result}) {
        $arg_ref->{_option_values} = $results->{option_values};
        $arg_ref->{parsed_args}    = $results->{parsed_args};

        # This exits.
        $class->usage(0) if ($results->{option_values}->{'help'});
    } else {
        # This exits.
        $class->usage(1);
    }

    return $arg_ref;
}

=head2 all_options

Returns the composition of options() and base_options() as list of L<App::Base::Script::Option> objects.

=cut

sub all_options {
    my $self = shift;
    state $cache;
    my $class = ref($self) || $self;
    $cache->{$class} //=
        [map { App::Base::Script::Option->new($_) } @{$self->options}, @{$self->base_options}];
    return $cache->{$class};
}

=head2 base_options

The options provided for every classes which implements App::Base::Script::Common.
See BUILT-IN OPTIONS

=cut

sub base_options {
    return [{
            name          => 'help',
            documentation => 'Show this help information',
        },
    ];
}

=head2 switch_name_width

Computes the maximum width of any of the switch (option) names.

=cut

sub switch_name_width {
    my $self = shift;
    return max(map { length($_->display_name) } @{$self->all_options});
}

=head2 switches

Generates the switch table output of the usage statement.

=cut

sub switches {
    my $self = shift;

    my $col_width = $ENV{COLUMNS} || 76;

    my $max_option_length = $self->switch_name_width;
    my $sw                = '[' x ($max_option_length + 2);
    my $doc               = '[' x ($col_width - $max_option_length - 1);

    my @lines = map { form {break => break_wrap}, "$sw $doc", '--' . $_->display_name, $_->show_documentation; }
        (sort { $a->name cmp $b->name } (@{$self->all_options}));

    return join('', @lines);
}

=head2 cli_template

The template usage form that should be shown to the user in the usage
statement when --help or an invalid invocation is provided.

Defaults to "(program name) [options]", which is pretty standard Unix.

=cut

sub cli_template {
    return "$0 [options] ";    # Override this if your script has a more complex command-line
                               # invocation template such as "$0[options] company_id [list1 [, list2 [, ...]]] "
}

=head2 usage

Outputs a statement explaining the usage of the script, then exits.

=cut

sub usage {
    my $self = shift;

    my $col_width = $ENV{COLUMNS} || 76;

    my $format = '[' x $col_width;

    my $message = join('', "\n", form({break => break_wrap}, $format, ["Usage: " . $self->cli_template, split(/[\r\n]/, $self->documentation)]));

    $message .= "\nOptions:\n\n";

    $message .= $self->switches . "\n\n";

    print STDERR $message;

    exit(1);

}

=head2 getOption

Returns the value of a specified option. For example, getOption('help') returns
1 or 0 depending on whether the --help option was specified. For option types
which are non-boolean (see App::Base::Script::Option) the return value is the actual
string/integer/float provided on the common line - or undef if none was provided.

=cut

sub getOption {
    my $self   = shift;
    my $option = shift;

    if (exists($self->_option_values->{$option})) {
        return $self->_option_values->{$option};
    } else {
        die "Unknown option $option";
    }

}

=head2 run

Runs the script, returning the return value of __run

=cut

sub run {
    my $self = shift;

    # This is implemented by subclasses of App::Base::Script::Common
    $self->__run;
    return $self->return_value;
}

=head2 _parse_arguments

Parses the arguments in @ARGV, returning a hashref containing:

=over 4

=item -

The parsed arguments (that is, those that should remain in @ARGV)

=item -

The option values, as a hashref, including default values

=item -

Whether the parsing encountered any errors

=back

=cut

sub _parse_arguments {
    my $self = shift;
    my $args = shift;

    local @ARGV = (@$args);

    # Build the hash of options to pass to Getopt::Long
    my $options      = $self->all_options;
    my %options_hash = ();
    my %getopt_args  = ();

    foreach my $option (@$options) {
        my $id   = $option->name;
        my $type = $option->option_type;
        if ($type eq 'string') {
            $id .= '=s';
        } elsif ($type eq 'integer') {
            $id .= '=i';
        } elsif ($type eq 'float') {
            $id .= '=f';
        }

        my $scalar = $option->default;
        $getopt_args{$option->name} = \$scalar;
        $options_hash{$id} = \$scalar;
    }

    my $result = GetOptions(%options_hash);
    my %option_values = map { $_ => ${$getopt_args{$_}} } (keys %getopt_args);
    return {
        parse_result  => $result,
        option_values => \%option_values,
        parsed_args   => \@ARGV
    };

}

=head2 __error

Dispatches its arguments to the subclass-provided error() method (see REQUIRED
SUBCLASS METHODS), then exits.

=cut

sub __error {
    my $self = shift;
    warn(join " ", @_);
    exit(-1);
}

no Moose::Role;
1;

__END__

=head1 USAGE

Invocation of a App::Base::Script::Common-based program is accomplished as follows:

=over 4

=item -

Define a class that derives (via 'use Moose' and 'with') from App::Base::Script::Common

=item -

Instantiate an object of that class via new( )

=item -

Run the program by calling run( ). The return value of run( ) is the exit
status of the script, and should typically be passed back to the calling
program via exit()

=back

=head2 The new() method

A Moose-style constructor for the App::Base::Script::Common-derived class.
Every such class has one important attribute: options -- an array ref of hashes
describing options to be added to the command-line processing for the script.
See L<App::Base::Script::Option> for more information.

=head2 Options handling

One of the most useful parts of App::Base::Script::Common is the simplified access to
options processing. The getOption() method allows your script to determine the
value of a given option, determined as follows:

=over 4

=item 1

If given as a command line option (registered via options hashref)

=item 2

The default value specified in the App::Base::Script::Option object that
was passed to the options() attribute at construction time.

=back

For example, if your script registers an option 'foo' by saying

    my $object = MyScript->new(
        options => [
            App::Base::Script::Option->new(
                name          => "foo",
                documentation => "The foo option",
                option_type   => "integer",
                default       => 7,
            ),
        ]
    );

Then in script_run() you can say

    my $foo = $self->getOption("foo")

And C<$foo> will be resolved as follows:

=over 4

=item 1

A --foo value specified as a command-line switch

=item 2

The default value specified at registration time ("bar")

=back

=head1 BUILT-IN OPTIONS

=head2 --help

Print a usage statement

=cut
