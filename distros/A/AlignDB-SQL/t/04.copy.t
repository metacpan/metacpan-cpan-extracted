#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('AlignDB::SQL');
}

sub ns {
    AlignDB::SQL->new;
}

my $stmt = ns();
ok $stmt, 'Created SQL object';

# Replace
$stmt = ns();
$stmt->add_select( foo        => 'foo' );
$stmt->add_select( 'COUNT(*)' => 'count' );
$stmt->from( [qw(baz)] );
$stmt->add_where( foo => 1 );
$stmt->group( { column => 'baz' } );
$stmt->order( { column => 'foo', desc => 'DESC' } );
$stmt->limit(2);
$stmt->add_having( count => 2 );
$stmt->replace( { foo => 'foobar', baz => 'barbaz' } );

my $stmt_copy = $stmt->copy;
is $stmt->as_sql, $stmt_copy->as_sql, "Copy, clone, duplicate or what ever";
