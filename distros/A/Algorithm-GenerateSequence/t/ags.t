#!perl -w
use strict;
use Test::More tests => 19;

my $class = 'Algorithm::GenerateSequence';
require_ok( $class );
my $iter = $class->new(
    [qw( alpha beta )], [qw( one two )], [qw( one two three )] );

isa_ok( $iter, $class );
is_deeply( [ $iter->next ], [qw( alpha one one )] );
is_deeply( [ $iter->next ], [qw( alpha one two )] );
is_deeply( [ $iter->next ], [qw( alpha one three )] );
is_deeply( [ $iter->next ], [qw( alpha two one )] );
is_deeply( [ $iter->next ], [qw( alpha two two )] );
is_deeply( [ $iter->next ], [qw( alpha two three )] );
is_deeply( [ $iter->next ], [qw( beta  one one )] );
is_deeply( [ $iter->next ], [qw( beta  one two )] );
is_deeply( [ $iter->next ], [qw( beta  one three )] );
is_deeply( [ $iter->next ], [qw( beta  two one )] );
is_deeply( [ $iter->next ], [qw( beta  two two )] );
is_deeply( [ $iter->next ], [qw( beta  two three )] );
ok( !$iter->next, "end" );
ok( !$iter->next, "still the end" );

$iter = $class->new(
    [qw( alpha beta )], [qw( one two )] );

isa_ok( $iter, $class );
is_deeply( [ $iter->() ], [qw( alpha one )], "new iter" );
is_deeply( [ $iter->as_list ], [
    [qw( alpha two )],
    [qw( beta  one )],
    [qw( beta  two )],
   ], "as_list" );
