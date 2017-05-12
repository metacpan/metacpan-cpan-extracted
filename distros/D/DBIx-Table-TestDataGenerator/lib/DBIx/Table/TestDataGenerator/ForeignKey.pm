package DBIx::Table::TestDataGenerator::ForeignKey;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use aliased 'DBIx::Table::TestDataGenerator::String';
use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';
use aliased 'DBIx::Table::TestDataGenerator::SelfReference';

has schema => (
    is       => 'ro',
    required => 1,
);

has table => (
    is       => 'ro',
    required => 1,
);

has handle_self_ref_wanted => (
    is       => 'ro',
    required => 1,
);

has pkey_col => (
    is       => 'ro',
    required => 1,
);

has pkey_col_names => (
    is       => 'ro',
    required => 1,
);

has roots_have_null_parent_id => (
    is      => 'ro',
    default => sub { return; },
);

has fkey_cols => (
    is       => 'ro',
    default  => sub { return []; },
    init_arg => undef,
);

has fkey_tables_ref => (
    is       => 'rw',
    init_arg => undef,
);

has fkey_self_ref => (
    is       => 'rw',
    init_arg => undef,
);

has all_refcol_to_col_dict => (
    is       => 'rw',
    init_arg => undef,
);

has all_refcol_lists => (
    is       => 'rw',
    init_arg => undef,
);

has handle_self_ref => (
    is       => 'rw',
    init_arg => undef,
);

has selfref_tree => (
    is       => 'rw',
    init_arg => undef,
);

has root => (
    is       => 'rw',
    init_arg => undef,
);

has parent_pkey_col => (
    is       => 'rw',
    init_arg => undef,
);

#We determine lists of foreign keys and tables referenced by these.
#For each foreign key constraint, the values of a (randomly selected)
#record from the referenced table will be used for a new test record.

#The referenced table may be the target table itself and in this case
#the parameter m_maxTreeDepth may come into play, see above.

sub BUILD {
    my ($self) = @_;

    #Define dictionaries relating the corresponding columns in the target
    #table to those in the referenced tables.
    $self->fkey_tables_ref( $self->_fkey_name_to_source( $self->table ) );

    #skip foreign key handling if there is none
    if ( keys %{ $self->fkey_tables_ref } == 0 ) {
        return;
    }
    $self->all_refcol_to_col_dict(
        $self->_fkey_referenced_cols_to_referencing_cols( $self->table ) );

    $self->all_refcol_lists( $self->_fkey_referenced_cols( $self->table ) );

    #If a self-reference is to be handled, define the tree of self-references
    #which will be used to determine the parent records later on.
    if (   $self->handle_self_ref_wanted
        && defined $self->pkey_col
        && @{ $self->pkey_col_names } == 1 )
    {
        my ( $r, $p ) =
          @{ SelfReference->get_self_reference( $self->schema, $self->table ) };

        $self->fkey_self_ref($r);
        $self->parent_pkey_col($p);

        if ( defined $self->fkey_self_ref && defined $self->parent_pkey_col ) {
            my ( $tree, $root ) = @{ SelfReference->selfref_tree(
                    $self->schema,   $self->table,
                    $self->pkey_col, $self->parent_pkey_col
                )
            };
            $self->selfref_tree($tree);
            $self->root($root);

            push @{ $self->fkey_cols }, $self->parent_pkey_col;

            $self->handle_self_ref(1);
        }
    }

    for ( values %{ $self->all_refcol_to_col_dict } ) {
        push @{ $self->fkey_cols }, values %{$_};
    }
    return;
}

sub _fkey_name_to_source {
    my ($self) = @_;
    my %fkey_to_src;
    my $pck_name = DBIxHelper->get_result_class( $self->schema, $self->table );
    my $source_name = String->remove_package_prefix($pck_name);
    my $s           = $self->schema->source($source_name);
    foreach my $rname ( $s->relationships ) {
        my $rel = $s->relationship_info($rname);
        if ( defined $rel->{attrs}->{is_foreign_key_constraint}
            && $rel->{attrs}->{is_foreign_key_constraint} eq '1' )
        {
            my $src = String->remove_package_prefix( $rel->{source} );
            $fkey_to_src{$rname} = $src;
        }
    }

    return \%fkey_to_src;
}

sub _fkey_referenced_cols_to_referencing_cols {
    my ($self) = @_;
    my %all_refcol_to_col_dict;

    my $src_descr = DBIxHelper->get_result_class( $self->schema, $self->table );

    my @fkey_names = keys %{ $self->_fkey_name_to_source( $self->table ) };

    foreach (@fkey_names) {
        my $fkey     = $_;
        my $rel_info = $src_descr->relationship_info($fkey);

        my %refcol_to_col_dict;

        my %col_relation = %{ $rel_info->{cond} };
        foreach my $cond ( keys %col_relation ) {
            my $own_col = $col_relation{$cond};
            $own_col =~ s /^self\.//;
            my $ref_col = $cond;
            $ref_col =~ s /^foreign\.//;

            $refcol_to_col_dict{$ref_col} = $own_col;
        }

        $all_refcol_to_col_dict{$fkey} = \%refcol_to_col_dict;
    }

    return \%all_refcol_to_col_dict;
}

sub _fkey_referenced_cols {
    my ($self) = @_;
    my %all_refcol_lists;

    my $src_descr = DBIxHelper->get_result_class( $self->schema, $self->table );

    my @fkey_names = keys %{ $self->_fkey_name_to_source( $self->table ) };

    foreach (@fkey_names) {
        my $fkey     = $_;
        my $rel_info = $src_descr->relationship_info($fkey);

        my @ref_col_list;

        my %col_relation = %{ $rel_info->{cond} };
        foreach my $cond ( keys %col_relation ) {
            my $ref_col = $cond;
            $ref_col =~ s /^foreign\.//;
            push @ref_col_list, $ref_col;
        }
        $all_refcol_lists{$fkey} = \@ref_col_list;
    }

    return \%all_refcol_lists;
}

1;    # End of DBIx::Table::TestDataGenerator::ForeignKey

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::ForeignKey - foreign key constraint information

=head1 DESCRIPTION

This class serves to determine information about foreign keys defined on the target table.

=head1 SUBROUTINES/METHODS

=head2 schema

Accessor for the DBIx::Class schema for the target database, required constructor argument.

=head2 table

Accessor for target table, required constructor argument.

=head2 handle_self_ref_wanted

Accessor for flag telling if the user wants a self-reference to be handled, required constructor argument.

=head2 pkey_col

Accessor for name of the primary key column which should be incremented for the new records, required constructor argument.

=head2 pkey_col_names

Accessor for names of the primary key columns, required constructor argument.

=head2 roots_have_null_parent_id

Accessor for option controlling whether root nodes are identified by "parent pkey = NULL" or "parent pkey = pkey". If true, the first case holds.

=head2 fkey_cols

Accessor for a list of all names of columns involved in foreign key constraints, externally read-only.

=head2 fkey_tables_ref

Accessor for a reference to a hash having as keys the names of foreign key constraints and as values the names of the referenced tables, externally read-only.

=head2 fkey_self_ref

Accessor for the name of the foreign key being a self-reference if it exists, undef otherwise, externally read-only.

=head2 all_refcol_to_col_dict

Accessor for a reference to a hash where the keys are the names of the foreign keys and for each foreign key, the value is a hash reference having as keys the names of the referenced columns and as values the names of the referencing columns, externally read-only.

=head2 all_refcol_lists

Accessor for a reference to a hash where the keys are the names of the foreign keys and for each foreign key, the value is a reference to an array containing the column names of the referenced columns, externally read-only.

=head2 handle_self_ref

Accessor for a flag which is set to true only if the caller wants to handle a self-reference (i.e. if handle_self_ref_wanted is true) and it has been determined that a self-reference exists, externally read-only.

=head2 selfref_tree

Accessor for a reference to a hash where, assuming there is a self-reference, each keys is the id of a parent record and the corresponding value a reference to an array containing the list of client node ids. If no self-reference exists, the value is undef. This accessor is externally read-only.

=head2 root

Accessor for the root of the self-reference tree, taken directly from the Tree class.

=head2 parent_pkey_col

Accessor for the name of the column containing parent ids in case of a self-reference, undef otherwise, externally read-only.

=head2 BUILD

Arguments: none

Determines foreign key constraint information with the help of the other internal methods.

=head2 _fkey_name_to_source

Arguments: none

Internal method. Returns a hash where the keys are the names of the foreign keys on the target table and the values the names of the corresponding referenced tables.

=head2 _fkey_referenced_cols_to_referencing_cols

Arguments: none

Internal method. Returns a reference to a dictionary having as keys the fkey names and for each key as value a dictionary where the keys are the names of the referenced column names and the values the names of the corresponding referencing column names.

=head2 _fkey_referenced_cols

Arguments: none

Internal method. Returns a reference to a hash having the fkey names as keys and a comma-separated list of the column names of the referenced columns of the fkey as values.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
