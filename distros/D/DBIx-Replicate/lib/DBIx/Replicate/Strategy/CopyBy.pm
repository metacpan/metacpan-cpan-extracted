# $Id: CopyBy.pm 22870 2008-11-06 16:06:55Z kazuho $

package DBIx::Replicate::Strategy::CopyBy;
use strict;
use warnings;
use Carp::Clan;
use List::Util qw/max min/;
use Time::HiRes qw/time sleep/;

sub new { bless {}, shift }

sub replicate
{
    my $self = shift;
    my $c    = shift;
    my $args = shift || {};

    foreach my $p qw(copy_by) {
        croak(ref($self) . ": required parameter $p is missing\n")
            unless $args->{$p};
    }

    my $copy_by = $args->{copy_by};
    # XXX Refactor later;
    my @columns = @{ $c->columns };
    my $columns_str = join ',', @columns;
    my $extra_cond = $c->extra_cond ?  sprintf("and %s", $c->extra_cond) : '';
    my $sql;
    
    my $block      = $c->block;
    my $src_table  = $c->src->table;
    my $dest_table = $c->dest->table;
    my $src_conn   = $c->src->conn;
    my $dest_conn  = $c->dest->conn;


    # copy using 'where key=x'
    croak "multi-column per-value copy not supported\n"
        unless @{$args->{copy_by}} == 1;
    croak "extra_cond not supported by copy_by\n"
        if $extra_cond;
    croak "limit_cond not supported by copy_by\n"
        if $c->limit_cond;
    my $key_col = $args->{copy_by}->[0];
    my $last_key;
    while (1) {
        my $start = time;

        $sql = sprintf(
            'select %s from %s where %s=(select min(%s) from %s where %s) %s',
            $columns_str,
            $src_table,
            $key_col,
            $key_col,
            $src_table,
            defined $last_key
                ? "$key_col>" . $src_conn->quote($last_key)
                    : '1',
            $extra_cond
        );
        my $rows = $src_conn->selectall_arrayref(
            $sql,
            { Slice => {} },
        ) or die $src_conn->errstr. "SQL: $sql";
        last unless @$rows;

        $dest_conn->begin_work
            or die $dest_conn->errstr;
        $sql = sprintf(
            'delete from %s where %s and %s<=%s',
            $dest_table,
            defined $last_key
                ? "$key_col>" . $dest_conn->quote($last_key)
                    : '1',
            $key_col,
            $dest_conn->quote($rows->[0]->{$key_col}),
        );
        $dest_conn->do($sql)
            or die $dest_conn->errstr;
        $last_key = $rows->[0]->{$key_col};
        while (@$rows) {
            $sql = "insert into $dest_table ($columns_str) values "
                . join(
                    ',',
                    map {
                        my $row = $_;
                        '(' . join(
                            ',',
                            map {
                                $dest_conn->quote($row->{$_})
                            } @columns
                        ) . ')'
                    } splice(
                        @$rows,
                        0,
                        min(scalar(@$rows), $block),
                    ),
                );
            $dest_conn->do($sql)
                or die $dest_conn->errstr;
        }
        $dest_conn->commit
            or die $dest_conn->errstr;
        sleep(max(time - $start, 0) * (1 - $args->{load}) / $args->{load})
            if $args->{load};
    }
    $sql = sprintf(
        'delete from %s where %s',
        $dest_table,
        defined $last_key
            ? "$key_col>" . $dest_conn->quote($last_key)
                : '1',
    );
    $dest_conn->do($sql)
        or die $dest_conn->errstr;
    
}

1;
