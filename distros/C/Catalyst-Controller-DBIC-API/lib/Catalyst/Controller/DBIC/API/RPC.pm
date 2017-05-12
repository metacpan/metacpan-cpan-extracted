package Catalyst::Controller::DBIC::API::RPC;
$Catalyst::Controller::DBIC::API::RPC::VERSION = '2.006002';
#ABSTRACT: Provides an RPC interface to DBIx::Class

use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API'; }

__PACKAGE__->config(
    'action'    => { object_with_id => { PathPart => 'id' } },
    'default'   => 'application/json',
    'stash_key' => 'response',
    'map'       => {
        'application/x-www-form-urlencoded' => 'JSON',
        'application/json'                  => 'JSON',
    },
);



sub create : Chained('objects_no_id') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;
    $self->update_or_create($c);
}


sub list : Chained('deserialize') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $self->next::method($c);
}


sub item : Chained('object_with_id') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->next::method($c);
}


sub update : Chained('object_with_id') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;
    $self->update_or_create($c);
}


sub delete : Chained('object_with_id') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    $self->next::method($c);
}


sub update_bulk : Chained('objects_no_id') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;
    $self->update_or_create($c);
}


sub delete_bulk : Chained('objects_no_id') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    $self->delete($c);
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::RPC - Provides an RPC interface to DBIx::Class

=head1 VERSION

version 2.006002

=head1 DESCRIPTION

Provides an RPC API interface to the functionality described in
L<Catalyst::Controller::DBIC::API>.

By default provides the following endpoints:

  $base/create
  $base/list
  $base/id/[identifier]
  $base/id/[identifier]/delete
  $base/id/[identifier]/update

Where $base is the URI described by L</setup>, the chain root of the controller.

=head1 PROTECTED_METHODS

=head2 setup

Chained: override
PathPart: override
CaptureArgs: 0

As described in L<Catalyst::Controller::DBIC::API/setup>, this action is the
chain root of the controller but has no pathpart or chain parent defined by
default.

These must be defined in order for the controller to function.

The neatest way is normally to define these using the controller's config.

  __PACKAGE__->config
    ( action => { setup => { PathPart => 'track', Chained => '/api/rpc/rpc_base' } },
	...
  );

=head2 create

Chained: L</objects_no_id>
PathPart: create
CaptureArgs: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/update_or_create>.

=head2 list

Chained: L</deserialize>
PathPart: list
CaptureArgs: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/list>.

=head2 item

Chained: L</object_with_id>
PathPart: ''
Args: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/item>.

=head2 update

Chained: L</object_with_id>
PathPart: update
Args: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/update_or_create>.

=head2 delete

Chained: L</object_with_id>
PathPart: delete
Args: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/delete>.

=head2 update_bulk

Chained: L</objects_no_id>
PathPart: update
Args: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/update_or_create> for multiple objects.

=head2 delete_bulk

Chained: L</objects_no_id>
PathPart: delete
Args: 0

Provides an endpoint to the functionality described in
L<Catalyst::Controller::DBIC::API/delete> for multiple objects.

=head1 AUTHORS

=over 4

=item *

Nicholas Perez <nperez@cpan.org>

=item *

Luke Saunders <luke.saunders@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Oleg Kostyuk <cub.uanic@gmail.com>

=item *

Samuel Kaufman <sam@socialflow.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Luke Saunders, Nicholas Perez, Alexander Hartmaier, et al..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
