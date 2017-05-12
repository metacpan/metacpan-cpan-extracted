use 5.10.1;
use strict;
use warnings;

package DBIx::Class::Visualizer::Relation;

# ABSTRACT: Handle relation information
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Moo;
use ReadonlyX;
use Types::Standard qw/Str Bool Enum/;
use PerlX::Maybe qw/provided/;

Readonly::Scalar my $HAS_MANY => 'has_many';
Readonly::Scalar my $BELONGS_TO => 'belongs_to';
Readonly::Scalar my $HAS_ONE => 'has_one';
Readonly::Scalar my $MIGHT_HAVE => 'might_have';

has added_to_graph => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

has origin_table => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has origin_column => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has destination_table => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has destination_column => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has cascade_delete => (
    is => 'ro',
    isa => Bool,
    predicate => 1,
);
has cascade_update => (
    is => 'ro',
    isa => Bool,
    predicate => 1,
);
has relation_type => (
    is => 'ro',
    isa => Enum[qw/has_many has_one belongs_to might_have/],
    required => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    my $relation = delete $args{'relation'};
    my $attr = $relation->{'attrs'};

    ($args{'destination_table'} = $relation->{'source'}) =~ s{^.*?::Result::}{};
    ($args{'origin_column'} = (values %{ $relation->{'cond'} })[0]) =~ s{^self\.}{};
    ($args{'destination_column'} = (keys %{ $relation->{'cond'} })[0]) =~ s{^foreign\.}{};

    for my $cascade (qw/cascade_delete cascade_update/) {
        $args{ $cascade } = $attr->{ $cascade } if exists $attr->{ $cascade };
    }

    # do not reorder
    $args{'relation_type'} = $attr->{'accessor'} eq 'multi' ? $HAS_MANY
                           : $attr->{'is_depends_on'}       ? $BELONGS_TO
                           : exists $attr->{'join_type'}    ? $MIGHT_HAVE
                           :                                  $HAS_ONE
                           ;

    $class->$orig(%args);
};

sub is_belongs_to { shift->relation_type eq $BELONGS_TO }

sub arrow_type {
    my $self = shift;

    return join '', $self->relation_type eq $HAS_MANY   ? qw/crow none odot/
                  : $self->relation_type eq $BELONGS_TO ? qw/none tee/
                  : $self->relation_type eq $MIGHT_HAVE ? qw/none tee none odot/
                  : $self->relation_type eq $HAS_ONE    ? qw/vee/
                  :                                       qw/dot dot dot/
                  ;
}

sub TO_JSON {
    my $self = shift;

    return +{
            origin_table => $self->origin_table,
            origin_column => $self->origin_column,
            destination_table => $self->destination_table,
            destination_column => $self->destination_column,
            relation_type => $self->relation_type,
        provided $self->has_cascade_delete,
            cascade_delete => $self->cascade_delete,
        provided $self->has_cascade_update,
            cascade_update => $self->cascade_update,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Visualizer::Relation - Handle relation information

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
