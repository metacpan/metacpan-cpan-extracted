package DBIx::Model;
use strict;
use warnings;
use DBIx::Model::DB;

our $VERSION = '0.0.1';

my %columns;
my %forward;
my %backward;

sub DBI::db::model {
    my $dbh     = shift;
    my $catalog = shift;
    my $schema  = shift;
    my $names   = shift // '%';
    my $type    = shift // 'TABLE,VIEW';

    my $db = DBIx::Model::DB->new(
        name        => $dbh->{Name},
        catalog     => $catalog,
        schema      => $schema,
        table_types => $type,
    );
    my @raw_fk;

    my $t_sth =
      $dbh->table_info( $db->catalog, $db->schema, $names, $db->table_types );

    my $trefs = $t_sth->fetchall_hashref('TABLE_NAME');
    foreach my $tname ( sort keys %$trefs ) {
        my $table = $db->add_table(
            name => $tname,
            type => $trefs->{$tname}->{TABLE_TYPE}
        );

        my @primary = $dbh->primary_key( $db->catalog, $db->schema, $tname );
        my $c_sth = $dbh->column_info( $db->catalog, $db->schema, $tname, '%' );

        while ( my $c_ref = $c_sth->fetchrow_hashref ) {
            my $pri = grep { $c_ref->{COLUMN_NAME} eq $_ } @primary;
            $table->add_column(
                name     => $c_ref->{COLUMN_NAME},
                nullable => $c_ref->{NULLABLE},
                size     => $c_ref->{COLUMN_SIZE},
                type     => $c_ref->{TYPE_NAME} || '*UNKNOWN*',
                primary  => $pri ? 1 : 0,
            );
        }

        my $fk_sth =
          $dbh->foreign_key_info( $db->catalog, $db->schema, undef,
            $db->catalog, $db->schema, $tname );

        my @x;
        while ( my $fk_ref = $fk_sth->fetchrow_hashref ) {
            next unless defined $fk_ref->{PKCOLUMN_NAME};    # mysql?

            if ( $fk_ref->{KEY_SEQ} == 1 ) {
                if (@x) {
                    push( @raw_fk, [@x] );
                }
                @x = (
                    lc $tname,
                    lc $fk_ref->{PKTABLE_NAME},
                    [
                        lc $fk_ref->{FKCOLUMN_NAME}, lc $fk_ref->{PKCOLUMN_NAME}
                    ]
                );
            }
            else {
                push(
                    @x,
                    [
                        lc $fk_ref->{FKCOLUMN_NAME}, lc $fk_ref->{PKCOLUMN_NAME}
                    ]
                );
            }
        }

        if (@x) {
            push( @raw_fk, [@x] );
        }
    }

    foreach my $fk (@raw_fk) {
        my ($from) =
          grep { $_->name_lc eq $fk->[0] } $db->tables;
        my ($to) = grep { $_->name_lc eq $fk->[1] } $db->tables;
        shift @$fk;
        shift @$fk;

        my @from;
        my @to;

        foreach my $pair (@$fk) {
            push( @from, grep { $_->name_lc eq $pair->[0] } $from->columns );
            push( @to,   grep { $_->name_lc eq $pair->[1] } $to->columns );
        }

        $from->add_foreign_key(
            to_table   => $to,
            columns    => \@from,
            to_columns => \@to,
        );

        map { $columns{ $_->full_name_lc } = $_ } @from, @to;
        map {
            $forward{ $to[$_]->full_name_lc }->{ $from[$_]->full_name_lc }++;
            $backward{ $from[$_]->full_name_lc }->{ $to[$_]->full_name_lc }++;
        } 0 .. ( ( scalar @from ) - 1 );
    }

    my $chain = 1;
    while ( my $key = ( sort keys %forward, keys %backward )[0] ) {
        chainer( $key, $chain++ );
    }

    $db->chains( $chain - 1 );
    %columns = %forward = %backward = ();
    return $db;
}

sub chainer {
    my $key   = shift;
    my $chain = shift;

    $columns{$key}->chain($chain);

    if ( my $val = delete $forward{$key} ) {
        foreach my $new ( sort keys %$val ) {
            chainer( $new, $chain );
        }
    }

    if ( my $val = delete $backward{$key} ) {
        foreach my $new ( sort keys %$val ) {
            chainer( $new, $chain );
        }
    }
}

1;

__END__

=encoding utf8

=head1 NAME

DBIx::Model - Build Perl objects of a database schema

=head1 VERSION

0.0.1 (2020-12-31)

=head1 SYNOPSIS

    use DBI;
    use DBIx::Model;

    my $dbh   = DBI->connect('dbi:SQLite:dbname=test.sqlite');
    my $model = $dbh->model;

    foreach my $table ( $model->tables ) {
        print $table->name . ' (' . $table->type . ")\n";
        foreach my $col ( $table->columns ) {
            print '  ' . $col->name;
            print ' ' . $col->type;
            print ' ' . ( $col->nullable ? '' : 'NOT NULL' );
            print "\n";
        }
    }

=head1 DESCRIPTION

B<DBIx::Model> builds Perl objects that reflect a database's schema,
using the standard C<table_info()>, C<column_info()>,
C<foreign_key_info()> and C<primary_key()> methods from L<DBI>.

=head1 INTERFACE

=head2 C<model( $catalog, $schema, $name, $type )>

Takes exactly the same arguments as C<DBI::table_info()> and method
returns a L<DBIx::Model::DB> object.

=head1 SEE ALSO

L<DBIx::Model::DB> - database object holding tables.

L<DBIx::Model::Table> - table objects holding columns and foreign key
info

L<DBIx::Model::Column> - column objects with references to foreign
columns

L<DBIx::Model::FK> - foreign key relationships

L<dbi2graphviz> - create schema diagrams using L<GraphViz2>.

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2016,2020 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

