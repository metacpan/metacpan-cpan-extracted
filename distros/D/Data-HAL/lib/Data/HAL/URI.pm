package Data::HAL::URI;
use strictures;
use Moo; # has
use Types::Standard qw(InstanceOf Str);
use URI qw();

our $VERSION = '1.000';

has('_original', is => 'rw', isa => Str);
# just records what was passed to the constructor, this is a work-around for
# URI->new being a lossy operation
has(
    'uri',
    is      => 'ro',
    isa     => InstanceOf['URI'],
    default => sub {
        my ($self) = @_;
        return URI->new($self->_original);
    },
    handles => [qw(abs as_iri canonical clone eq fragment implementor new_abs opaque path rel scheme secure
                STORABLE_freeze STORABLE_thaw)],
    lazy    => 1,
    required => 1,
);

sub BUILDARGS {
    my (undef, @arg) = @_;
    return 1 == @arg ? {_original => $arg[0]} : {@arg};
}

sub as_string {
    my ($self, $root) = @_;
    if (
        $self->eq($self->_original)
        ||
        $root && $root->_nsmap && $self->uri->eq($root->_nsmap->uri($self->_original)->as_string)
    ) {
        return $self->_original;
    } else {
        return $self->uri->as_string;
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Data::HAL::URI - URI wrapper

=head1 VERSION

This document describes Data::HAL::URI version 1.000

=head1 SYNOPSIS

    my $relation = $resource->relation->as_string;

=head1 DESCRIPTION

This is a wrapper for L<URI> objects.

=head1 INTERFACE

=head2 Composition

None, but L<URI> methods are delegated through the L</uri> attribute.

=head2 Constructors

=head3 C<new>

    my $u = Data::HAL::URI->new('http://example.com/something');

Takes a string argument, returns a C<Data::HAL::URI> object.

=head2 Attributes

=head3 C<uri>

Type C<URI>, B<required>, B<readonly>, can only be set from the L</new> constructor.

This attribute delegates all methods to L<URI> except L</as_string>.

=head2 Methods

=head3 C<as_string>

Returns the original argument to the constructor if still equal to the L</uri>, where equality also takes CURIE
expansion into account, or otherwise the L</uri> as string.

The unaltered behaviour is still available through the L</uri> accessor, e.g.:

    $resource->relation->uri->as_string

=head2 Exports

None.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.
