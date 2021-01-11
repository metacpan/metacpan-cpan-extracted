package DNS::Unbound::AsyncQuery;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound::AsyncQuery

=head1 SYNOPSIS

    my $dns = DNS::Unbound->new();

    my $query = $dns->resolve_async( 'example.com', 'A' );

    # Ordinary ES6 Promise semantics:
    $query->then( .. )->then( .. );

    $query->cancel();

=head1 DESCRIPTION

This object represents the result of an asynchronous L<DNS::Unbound> query.
It implements a standard promise interface
and also provides a cancellation mechanism.

The promise resolves with a L<DNS::Unbound::Result> instance.
It rejects with a L<DNS::Unbound::X::ResolveError> instance
that describes the failure.

=cut

#----------------------------------------------------------------------

# A hack to prevent a circular dependency with DNS::Unbound.
# There doesn’t seem to be a better way to do this without having to
# version an XS module separately from the distribution itself,
# which is just annoying. That said, this doubles nicely as a
# mocking mechanism for tests.
our $CANCEL_CR;

#----------------------------------------------------------------------

=head1 METHODS

In addition to the C<then()>, C<catch()>, and C<finally()> methods—see
L<Promise::ES6> if you’re unsure of how to use those—this class provides:

=cut

=head2 I<OBJ>->cancel()

Cancels an in-progress DNS query. Returns nothing.

B<NOTE:> This will leave the promise I<unresolved>.

=cut

sub cancel {
    my ($self) = @_;

    my $dns_hr = $self->_get_dns();

    if (!$dns_hr->{'fulfilled'}) {
        if (my $ctx = delete $dns_hr->{'ctx'}) {
            delete $dns_hr->{'queries_lookup'}{ $dns_hr->{'id'} };
            $CANCEL_CR->( $ctx, $dns_hr->{'id'} );
        }
    }

    return;
}

# Leaving undocumented since as far as the caller is concerned
# this method is identical to the parent class’s.
sub then {

    # We need to use the promise backend’s then(), but that backend isn’t
    # a parent class of *this* class, so we can’t call SUPER::then().
    # Thus, the backend bridge module aliases the backend then() to
    # _then(), and we call into that.

    my $new = $_[0]->_dns_unbound_then(@_[1, 2]);

    $new->_set_dns( $_[0]->_get_dns() );

    return $new;
}

# Not all promise implementations define these as wrappers around then().
# So let’s be explicit about it:
sub catch {
    return $_[0]->then( undef, $_[1] );
}

sub finally {

    my $new = $_[0]->_dns_unbound_finally($_[1]);

    $new->_set_dns( $_[0]->_get_dns() );

    return $new;
}

# ----------------------------------------------------------------------
# Interfaces for DNS::Unbound to interact with the query’s DNS state.
# Nothing external should call these other than DNS::Unbound.

my %QUERY_OBJ_DNS;

sub _set_dns {
    my ($self, $dns_hr) = @_;

    $QUERY_OBJ_DNS{$self} = $dns_hr;

    return $self;
}

sub _get_dns {
    return $QUERY_OBJ_DNS{$_[0]};
}

sub DESTROY {
    my $self = shift;

    delete $QUERY_OBJ_DNS{$self};

    $self->SUPER::DESTROY() if $self->can('SUPER::DESTROY');

    return;
}

1;
