package Catalyst::Controller::DBIC::API::Request::Context;
$Catalyst::Controller::DBIC::API::Request::Context::VERSION = '2.006002';
#ABSTRACT: Provides additional context to the Request
use Moose::Role;
use MooseX::Types::Moose(':all');
use MooseX::Types::Structured('Tuple');
use Catalyst::Controller::DBIC::API::Types(':all');
use namespace::autoclean;


has objects => (
    is     => 'ro',
    isa    => ArrayRef[Tuple[Object,Maybe[HashRef]]],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        all_objects   => 'elements',
        add_object    => 'push',
        count_objects => 'count',
        has_objects   => 'count',
        clear_objects => 'clear',
        get_object    => 'get',
    },
);


has current_result_set => (
    is     => 'ro',
    isa    => ResultSet,
    writer => '_set_current_result_set',
);

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::Request::Context - Provides additional context to the Request

=head1 VERSION

version 2.006002

=head1 PUBLIC_ATTRIBUTES

=head2 objects

This attribute stores the objects found/created at the object action.
It handles the following methods:

    all_objects   => 'elements'
    add_object    => 'push'
    count_objects => 'count'
    has_objects   => 'count'
    clear_objects => 'clear'

=head2 current_result_set

Stores the current ResultSet derived from the initial
L<Catalyst::Controller::DBIC::API::StoredResultSource/stored_model>.

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
