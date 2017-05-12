package Catalyst::Controller::DBIC::API::Request;
$Catalyst::Controller::DBIC::API::Request::VERSION = '2.006002';
#ABSTRACT: Provides a role to be applied to the Request object
use Moose::Role;
use MooseX::Types::Moose(':all');
use namespace::autoclean;

#XXX HACK to satisfy the used roles requirements
# see Moose test todo_tests/required_role_accessors.t
sub _application { }
sub _controller  { }


has '_application' => (
    is     => 'ro',
    writer => '_set_application',
    isa    => Object | ClassName,
);

has '_controller' => (
    is      => 'ro',
    writer  => '_set_controller',
    isa     => Object,
    trigger => sub {
        my ( $self, $new ) = @_;

        $self->_set_class( $new->class ) if defined( $new->class );
        $self->_set_application( $new->_application );
        $self->_set_search_exposes( $new->search_exposes );
        $self->_set_select_exposes( $new->select_exposes );
    },
    handles => ['prefetch_validator'],
);

with 'Catalyst::Controller::DBIC::API::StoredResultSource',
    'Catalyst::Controller::DBIC::API::RequestArguments',
    'Catalyst::Controller::DBIC::API::Request::Context';


1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::Request - Provides a role to be applied to the Request object

=head1 VERSION

version 2.006002

=head1 DESCRIPTION

Please see L<Catalyst::Controller::DBIC::API::RequestArguments> and
L<Catalyst::Controller::DBIC::API::Request::Context> for the details of this
class, as both of those roles are consumed in this role.

=head1 PRIVATE_ATTRIBUTES

=head2 _application

This attribute helps bridge between the request guts and the application guts;
allows request argument validation against the schema. This is set during
L<Catalyst::Controller::DBIC::API/inflate_request>.

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
