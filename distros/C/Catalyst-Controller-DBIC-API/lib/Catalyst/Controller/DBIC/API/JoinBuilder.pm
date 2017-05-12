package Catalyst::Controller::DBIC::API::JoinBuilder;
$Catalyst::Controller::DBIC::API::JoinBuilder::VERSION = '2.006002';
#ABSTRACT: Provides a helper class to automatically keep track of joins in complex searches
use Moose;
use MooseX::Types::Moose(':all');
use Catalyst::Controller::DBIC::API::Types(':all');
use namespace::autoclean;


has parent => (
    is        => 'ro',
    isa       => JoinBuilder,
    predicate => 'has_parent',
    weak_ref  => 1,
    trigger   => sub { my ( $self, $new ) = @_; $new->add_child($self); },
);


has children => (
    is      => 'ro',
    isa     => ArrayRef [JoinBuilder],
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        all_children => 'elements',
        has_children => 'count',
        add_child    => 'push',
    }
);


has joins => (
    is         => 'ro',
    isa        => HashRef,
    lazy_build => 1,
);


has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


sub _build_joins {
    my ($self) = @_;

    my $parent;
    while ( my $found = $self->parent ) {
        if ( $found->has_parent ) {
            $self = $found;
            next;
        }
        $parent = $found;
    }

    my $builder;
    $builder = sub {
        my ($node) = @_;
        my $foo = {};
        map { $foo->{ $_->name } = $builder->($_) } $node->all_children;
        return $foo;
    };

    return $builder->( $parent || $self );
}


1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::JoinBuilder - Provides a helper class to automatically keep track of joins in complex searches

=head1 VERSION

version 2.006002

=head1 DESCRIPTION

JoinBuilder is used to keep track of joins automagically for complex searches.
It accomplishes this by building a simple tree of parents and children and then
recursively drilling into the tree to produce a useable join attribute for
search.

=head1 PUBLIC_ATTRIBUTES

=head2 parent

Stores the direct ascendant in the datastructure that represents the join.

=head2 children

Stores the immediate descendants in the datastructure that represents the join.

Handles the following methods:

    all_children => 'elements'
    has_children => 'count'
    add_child    => 'push'

=head2 joins

Holds the cached, generated join datastructure.

=head2 name

Sets the key for this level in the generated hash.

=head1 PRIVATE_METHODS

=head2 _build_joins

Finds the top parent in the structure and then recursively iterates the children
building out the join datastructure.

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
