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
ok( $stmt, 'Created SQL object' );

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
is strip($stmt->as_sql),
    "SELECT foobar, COUNT(*) count FROM barbaz WHERE (foobar = ?) GROUP BY barbaz HAVING (COUNT(*) = ?) ORDER BY foobar DESC LIMIT 2";

# Replace with meta-char
$stmt = ns();
$stmt->add_select( 'foo.bar'  => 'foo.bar' );
$stmt->add_select( 'COUNT(*)' => 'count' );
$stmt->from( [qw(baz)] );
$stmt->replace( { 'foo.bar' => 'foo.foobar' } );
is strip($stmt->as_sql), "SELECT foo.foobar, COUNT(*) count FROM baz";
