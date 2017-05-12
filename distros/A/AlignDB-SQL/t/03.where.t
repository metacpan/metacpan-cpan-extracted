#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('AlignDB::SQL');
}

sub ns {
    AlignDB::SQL->new;
}

sub strip {
    $_[0] =~ s/\s+/ /g;
    $_[0] =~ s/ $//s;
    return $_[0];
}

my $stmt = ns();
ok $stmt, 'Created SQL object';

## Testing WHERE
$stmt = ns();
$stmt->add_where( foo => 'bar' );
$stmt->add_where( foo => [ 'bar', 'baz' ] );
$stmt->add_where( foo => { op => '!=', value => 'bar' } );
$stmt->add_where( foo => { column => 'bar', op => '!=', value => 'bar' } );
$stmt->add_where( foo => \'IS NOT NULL' );
$stmt->add_where(
    foo => [ { op => '>', value => 'bar' }, { op => '<', value => 'baz' } ] );
$stmt->add_where(
    foo => [
        -and => { op => '>', value => 'bar' },
        { op => '<', value => 'baz' }
    ]
);
print $stmt->as_sql;

#$stmt = ns();
#is( $stmt->as_sql_where,     "WHERE ((foo > ?) AND (foo < ?))\n" );
#is( scalar @{ $stmt->bind }, 2 );
#is( $stmt->bind->[0],        'bar' );
#is( $stmt->bind->[1],        'baz' );
#
#$stmt = ns();
#$stmt->add_where( foo => [ -and => 'foo', 'bar', 'baz' ] );
#is( $stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?))\n" );
#is( scalar @{ $stmt->bind }, 3 );
#is( $stmt->bind->[0],        'foo' );
#is( $stmt->bind->[1],        'bar' );
#is( $stmt->bind->[2],        'baz' );
#
## regression bug. modified parameters
my %terms = ( foo => [ -and => 'foo', 'bar', 'baz' ] );
$stmt = ns();
$stmt->add_where(%terms);
is strip( $stmt->as_sql_where ),
    "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?))";
$stmt->add_where(%terms);
is strip( $stmt->as_sql_where ),
    "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?)) AND ((foo = ?) AND (foo = ?) AND (foo = ?))";
