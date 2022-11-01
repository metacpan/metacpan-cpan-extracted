package App::Base::Script::Option;
use Moose;

our $VERSION = '0.08';    ## VERSION

=head1 NAME

App::Base::Script::Option - OO interface for command-line options

=head1 SYNOPSIS

    my $option = App::Base::Script::Option->new(
        {
            name          => 'foo',
            display       => '--foo=<f>',
            documentation => 'Controls the foo behavior of my script.',
            default       => 4,
            option_type   => 'integer',
        }
    );

=head1 DESCRIPTION

App::Base::Script::Option is used by App::Base::Script::Common and its
descendents to implement the standard definition of command-
line options. Typically an object of this class will be
constructed anonymously as part of the anonymous arrayref
return value of the options() method:

    sub options {
        return [
            App::Base::Script::Option->new(
                name          => 'foo',
                documentation => 'The foo option',
                option_type   => 'integer',
            ),
            App::Base::Script::Option->new(
                name          => 'bar',
                documentation => 'The bar option',
            ),
        ];
    }

=head1 ATTRIBUTES

=head2 name

The name of the attribute that must be specified on the command line.
This name follows Getopt::Long rules, so its usage can be reduced to
the shortest unambiguous specification. In other words, if the options
'fibonacci' and 'fortune' are options to the same script, then --fi
and --fo are valid options but -f (or --f) are not because of the
ambiguity between the two options.

=head2 display

The name as it is displayed in a usage (--help) option (switch) table.
By default, it is the same as the name; this method is provided for
cases in which it may be helpful to have a usage statement that shows
a sample value such as '--max-timeout=<timeout>' rather than simply
saying '--max-timeout', because the meaning of --max-timeout is then
explained in terms of <timeout> in the documentation for the option.

=head2 documentation

A scalar (string) which documents the behavior of the option. REQUIRED.

=head2 default

The default value of the option, if any.

=head2 option_type

One of: 'integer', 'float', 'string', or 'switch'.

The content of an option field is verified against the provided value
during option parsing. For example, --foo=Fred will cause a failure
if the 'foo' option was declared to have option_type 'integer'.

=cut

use MooseX::Types -declare => [qw(script_option_type)];
use MooseX::Types::Moose qw( Str );

subtype script_option_type, as Str, where {
    $_ =~ /^(integer|float|string|switch)$/;
}, message {
    "Invalid option type $_";
};

has [qw(name documentation)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [qw(default display)] => (
    is => 'ro',
);

has [qw(option_type)] => (
    is      => 'ro',
    isa     => script_option_type,
    default => 'switch',
);

=head1 METHODS

=head2 display_name

Returns the display name of the option, which is either $self->display or
(if $self->display is not defined) $self->name. This value is used to
generate the switch table documentation.

=cut

sub display_name {
    my $self = shift;
    if ($self->display) {
        return $self->display;
    } else {
        return $self->name;
    }
}

=head2 show_documentation

Returns documentation string for the option

=cut

sub show_documentation {
    my $self = shift;
    if ($self->default) {
        return $self->documentation . ' (default: ' . $self->default . ')';
    } else {
        return $self->documentation;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
