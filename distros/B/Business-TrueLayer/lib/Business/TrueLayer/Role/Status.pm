package Business::TrueLayer::Role::Status;

=head1 NAME

Business::TrueLayer::Role::Status

A role for attributes and behviour related to status

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose::Role;
no warnings qw/ experimental::signatures experimental::postderef /;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item status (Str)

=back

=cut

has [ qw/ status / ] => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head2 METHODS

=head2 authorization_required

=head2 authorizing

=head2 authorized

=head2 executed

=head2 settled

=head2 failed

Check if the resource is at a current state:

    if ( $Resouce->authorizing ) {
        ...
    }

=cut

sub authorization_required {
    shift->_is_status( 'authorization_required' );
}

sub authorizing { shift->_is_status( 'authorizing' ); }
sub authorized  { shift->_is_status( 'authorized' ); }
sub executed    { shift->_is_status( 'executed' ); }
sub revoked     { shift->_is_status( 'revoked' ); }
sub settled     { shift->_is_status( 'settled' ); }
sub failed      { shift->_is_status( 'failed' ); }

sub remitter_changed {
    shift->_is_status( 'remitter_changed' );
}

sub _is_status ( $self,$status ) {
    return ( $self->status // '' ) eq $status ? 1 : 0;
}

1;
