package DBIx::Table::TestDataGenerator::SelfReference;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use Data::GUID;

use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';

sub _self_ref_condition {
    my ( $self, $schema, $table ) = @_;
    my %col_relations;
    my $result_class = DBIxHelper->get_result_class( $schema, $table );
    foreach my $sname ( $schema->sources ) {
        my $s = $schema->source($sname);
        foreach my $rname ( $s->relationships ) {
            my $rel = $s->relationship_info($rname);
            if (   $rel->{class} eq $result_class
                && defined $rel->{attrs}->{is_foreign_key_constraint}
                && $rel->{attrs}->{is_foreign_key_constraint} eq '1' )
            {
                my %cols = %{ $rel->{cond} };
                foreach my $referenced_col ( keys %cols ) {
                    my $referencing_col = $cols{$referenced_col};

                    $referenced_col  =~ s/(?:.*\.)?(.+)/$1/;
                    $referencing_col =~ s/(?:.*\.)?(.+)/$1/;

                    $col_relations{$referenced_col} =
                      { '=' => \$referencing_col };
                }
                return [ $rname, \%col_relations ];
            }
        }
    }
    return;
}

sub get_self_reference {
    my ( $self, $schema, $table ) = @_;

    my $self_ref_cond = $self->_self_ref_condition( $schema, $table );
    my ( $fkey_name, $col_relations ) = @$self_ref_cond;
    my %rel              = %{$col_relations};
    my @referencing_cols = keys %rel;
    my %h                = %{ ( values %rel )[0] };
    return [ $fkey_name, ${ ( values %h )[0] } ];
}

sub selfref_tree {
    my ( $self, $schema, $table, $child_col, $parent_col ) = @_;
    my $cls = DBIxHelper->get_result_class( $schema, $table );
    my $rs = $schema->resultset($cls)->search();
    my %tree;
    my $root_id = Data::GUID->new->as_hex;

    while ( my $rec = $rs->next() ) {
        my $parent = $rec->get_column($parent_col);
        my $child  = $rec->get_column($child_col);

        #in case $parent is undef or the same as $child, we have a root node
        #and set the parent id to NULL
        $parent = $root_id if !$parent || $parent == $child;
        $tree{$parent} //= [];
        push @{ $tree{$parent} }, $child;
    }
    return [ \%tree, $root_id ];
}

sub num_roots {
    my ( $self, $schema, $table, $roots_have_null_parent_id ) = @_;
    my $cls = DBIxHelper->get_result_class( $schema, $table );

    #find name of foreign key on target table being a self reference
    my $self_ref_cond = $self->_self_ref_condition( $schema, $table );

    if ($roots_have_null_parent_id) {
        my $referencing_col = @{$self_ref_cond}[0];
        return $schema->resultset($cls)
          ->search( { $referencing_col => { '=' => undef } } )->count;
    }
    else {
        my $col_relations = @{$self_ref_cond}[1];
        return $schema->resultset($cls)->search($col_relations)->count;
    }
}

1;    # End of DBIx::Table::TestDataGenerator::SelfReference

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::SelfReference - self-reference handling

=head1 DESCRIPTION

Determines if there is a self-reference and if so, information about it.

=head1 SUBROUTINES/METHODS

=head2 _self_ref_condition

=over 4

=item * schema: DBIx schema of the target database

=item * table: Name of the target table

=back

Internal method, returns the name of the foreign key defining a self-reference and a hash relating the referencing to the referenced column in case there is a self-reference, returns undef otherwise.

=head2 get_self_reference

=over 4

=item * schema: DBIx schema of the target database

=item * table: Name of the target table

=back

If there is an fkey defining a self-reference, its name and the name of the referencing column are returned in a two-element array reference, otherwise undef is returned.

=head2 selfref_tree

Arguments:

=over 4

=item * schema: DBIx schema of the target database

=item * table: Name of the target table

=item * child_col: Name of the (unique) primary key column

=item * parent_col: Name of the column referencing the primary key column

=back

Returns a hash corresponding to the self-reference defined on the table.

=head2 num_roots

Arguments:

=over 4

=item * schema: DBIx schema of the target database

=item * table: Name of the target table

=back

Returns the number of roots in the target table in case a self-reference exists on it. A record is considered a root node if either the value for the parent primary key is equal to NULL or to the record's primary key value.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.
