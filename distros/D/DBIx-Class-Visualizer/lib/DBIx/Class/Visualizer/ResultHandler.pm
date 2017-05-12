use 5.10.1;
use strict;
use warnings;

package DBIx::Class::Visualizer::ResultHandler;

# ABSTRACT: Handle result sources and related information
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Moo;
use Types::Standard qw/Bool ArrayRef HashRef InstanceOf Int/;
use PerlX::Maybe;
use List::Util qw/any/;
use Syntax::Keyword::Gather;
use DBIx::Class::Visualizer::Relation;
use DBIx::Class::Visualizer::Column;

has name => (
    is => 'ro',
    required => 1,
);
has rs => (
    is => 'ro',
    required => 1,
);
has show => (
    is => 'rw',
    isa => Bool,
    default => 1,
);
has wanted => (
    is => 'ro',
    isa => Bool,
    default => 0,
);
has skip => (
    is => 'ro',
    isa => Bool,
    default => 0,
);
has columns => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['DBIx::Class::Visualizer::Column']],
    lazy => 1,
    builder => 1,
);
has only_keys => (
    is => 'ro',
    isa => Bool,
    default => 0,
);
has relations => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['DBIx::Class::Visualizer::Relation']],
    lazy => 1,
    builder => 1,
);
has _degree_of_separation => (
    is => 'rw',
    isa => Int,
    init_arg => 'degree_of_separation',
    predicate => 1,
);
sub degree_of_separation {
    my $self = shift;
    my $value = shift;
    return 0 if !defined $value && !$self->_has_degree_of_separation;
    return $self->_degree_of_separation if $self->_has_degree_of_separation && !defined $value;
    return $self->_degree_of_separation if $self->_has_degree_of_separation && $value > $self->_degree_of_separation;
    $self->_degree_of_separation($value);
}

sub _build_columns {
    my $self = shift;

    my @primary_columns = $self->rs->primary_columns;

    return [
        gather {
            COLUMN:
            for my $column_name ($self->rs->columns) {

                my $column_info = $self->rs->column_info($column_name);
                my $is_primary = (any { $column_name eq $_ } @primary_columns) ? 1 : 0;
                my $is_foreign = $column_info->{'is_foreign_key'} ? 1 : 0;

                next COLUMN if !$is_primary && !$is_foreign && $self->only_keys;

                take(DBIx::Class::Visualizer::Column->new(
                    name => $column_name,
                    %{ $column_info },
                    is_primary_key => $is_primary,
                    relations => [$self->get_relations($column_name)],
                ));
             }
        }
    ];
}

sub _build_relations {
    my $self = shift;

    my @relationship_names = $self->rs->relationships;

    return [
        gather {
            RELATION:
            for my $relation_name (@relationship_names) {
                my $relation = $self->rs->relationship_info($relation_name);
                next RELATION if ref $relation->{'cond'} ne 'HASH' || scalar keys %{ $relation->{'cond'} } != 1;

                take(DBIx::Class::Visualizer::Relation->new(origin_table => $self->name, relation => $relation));
            }
        }
    ];
}

sub get_relations {
    my $self = shift;
    my $column_name = shift;

    return grep { $_->origin_column eq $column_name } @{ $self->relations };
}

# find the relation from $origin_column in this result_source that points to $destination_table.$destination_column
sub get_relation_between {
    my $self = shift;
    my $origin_column = shift;
    my $destination_table = shift;
    my $destination_column = shift;

    return (grep { $_->destination_table eq $destination_table && $_->destination_column eq $destination_column } $self->get_relations($origin_column))[0];
}
sub get_column {
    my $self = shift;
    my $column_name = shift;
    return (grep { $column_name eq $_->name } @{ $self->columns })[0];
}

# Node names can't have colons in them.
sub node_name {
    my $node_name = shift->name;
    $node_name =~ s{::}{__}g;
    return $node_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Visualizer::ResultHandler - Handle result sources and related information

=head1 VERSION

Version 0.0200, released 2016-09-19.

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Visualizer>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Visualizer>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
