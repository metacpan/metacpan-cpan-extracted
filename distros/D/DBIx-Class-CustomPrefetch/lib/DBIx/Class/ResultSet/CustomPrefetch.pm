package DBIx::Class::ResultSet::CustomPrefetch;

use utf8;
use strict;
use warnings;
use MRO::Compat;
use mro 'c3';
use parent 'DBIx::Class::ResultSet';
use constant DEBUG => 0;

=head1 NAME

DBIx::Class::ResultSet::CustomPrefetch

=head1 DESCRIPTION

DBIx::Class allows prefetches only using joins. But sometimes you can't use JOIN for prefetch. E.g. for prefetching
many related objects to resultset with paging.

This module provides other logic for prefetching data to resultsets.

=head1 METHODS

=cut

sub _prefetch_relation {
    my ( $self, $accessor_name, $rs_callback, $condition ) = @_;
    my $resultset =
      ref $rs_callback
      ? $rs_callback->( $self->result_source->schema, $self->{attrs} )
      : $self->result_source->schema->resultset($rs_callback);
    return unless $resultset;  
    my $objects   = $self->get_cache;
    my %ids       = ();
    my %relations = ();
    my ( $foreign_accessor, $source_accessor ) = %$condition;
    $foreign_accessor =~ s/^foreign\.//;
    $source_accessor  =~ s/^self\.//;

    foreach (@$objects) {
        next unless defined $_->$source_accessor;
        $ids{ $_->$source_accessor } = 1;
    }
    my $related_source_alias = $resultset->current_source_alias;
    my @related_objects;
    @related_objects = $resultset->search(
        {
            "$related_source_alias.$foreign_accessor" =>
              { -in => [ keys %ids ] }
        },
    )->all if %ids;
    push @{ $relations{ $_->$foreign_accessor } }, $_ foreach @related_objects;
    warn "Setting accessors:\n" if DEBUG;
    foreach (@$objects) {
        warn "$_ $accessor_name => $source_accessor\n" if DEBUG;
        $_->$accessor_name( $relations{ $_->$source_accessor || '' }[0] );
    }
}

=head2 all

Prefetches predefined relations

=cut

sub all {
    my ( $self, @args ) = @_;
    warn "Enter SUB: " . (ref $self) . "\n" if DEBUG;
    my @objects = $self->next::method(@args);
    $self->set_cache( \@objects );
    foreach ( values %{ $self->result_source->{_custom_relations} } ) {
        warn "Prefetching $_->[0]\n" if DEBUG;
        $self->_prefetch_relation(@$_);
    }
    return @objects;
}

=head2 next

Retrieves ALL relations and does next::method

=cut

sub next {
    my $self = shift;
    $self->all;
    $self->next::method(@_);
}

=head1 BUGS

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko (), <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

17.06.2009 18:12:46 MSD

=cut

1;

