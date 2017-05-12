use 5.10.1;
use strict;
use warnings;

package DBIx::Class::Visualizer::Column;

# ABSTRACT: Handle column information
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Moo;
use DBIx::Class::Visualizer::Relation;
use Types::Standard qw/ArrayRef InstanceOf/;
use PerlX::Maybe qw/provided/;

has name => (
    is => 'ro',
    required => 1,
);
has data_type => (
    is => 'ro',
    required => 1,
);
has relations => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['DBIx::Class::Visualizer::Relation']],
    lazy => 1,
    default => sub { [] },
);

has is_primary_key => (
    is => 'ro',
    default => 0,
);
has is_foreign_key => (
    is => 'ro',
    default => 0,
);
has is_nullable => (
    is => 'ro',
    default => 0,
);

has accessor => (
    is => 'ro',
    predicate => 1,
);
has size => (
    is => 'ro',
    predicate => 1,
);
has is_auto_increment => (
    is => 'ro',
    predicate => 1,
);
has is_numeric => (
    is => 'ro',
    predicate => 1,
);
has default_value => (
    is => 'ro',
    predicate => 1,
);
has sequence => (
    is => 'ro',
    predicate => 1,
);
has retrieve_on_insert => (
    is => 'ro',
    predicate => 1,
);
has unsigned => (
    is => 'ro',
    predicate => 1,
);
has extra => (
    is => 'ro',
    predicate => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    if(exists $args{'extra'}{'unsigned'}) {
        $args{'unsigned'} = delete $args{'extra'}{'unsigned'};
    }
    # Dereference default values like \'now()'
    if(exists $args{'default_value'}) {
        if(ref $args{'default_value'} eq 'SCALAR') {
            $args{'default_value'} = ${ $args{'default_value'} };
        }
        # ..and put quotes around string default values
        else {
            $args{'default_value'} = qq{'$args{'default_value'}'};
        }
    }

    # remove things like _inflate_info
    map { delete $args{ $_ } } grep { /^_/ } keys %args;

    $class->$orig(%args);
};

sub column_name_label_tag {
    my $self = shift;

    my $column_name_tag = $self->name;
    $column_name_tag = $self->{'is_primary_key'} ? "<b>$column_name_tag</b>" : $column_name_tag;
    $column_name_tag = $self->{'is_foreign_key'} ? "<u>$column_name_tag</u>" : $column_name_tag;
    return $column_name_tag;
}

sub TO_JSON {
    my $self = shift;

    return +{
        name => $self->name,
        data_type => $self->data_type,
        relations => [map { $_->TO_JSON } @{ $self->relations }],
        is_primary_key => $self->is_primary_key,
        is_foreign_key => $self->is_foreign_key,
        is_nullable => $self->is_nullable,
        provided $self->has_accessor,           accessor => $self->accessor,
        provided $self->has_size,               size => $self->size,
        provided $self->has_is_auto_increment,  is_auto_increment => $self->is_auto_increment,
        provided $self->has_is_numeric,         is_numeric => $self->is_numeric,
        provided $self->has_default_value,      default_value => $self->default_value,
        provided $self->has_sequence,           sequence => $self->sequence,
        provided $self->has_retrieve_on_insert, retrieve_on_insert => $self->retrieve_on_insert,
        provided $self->has_unsigned,           unsigned => $self->unsigned,
        provided $self->has_extra,              extra => $self->extra,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Visualizer::Column - Handle column information

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
