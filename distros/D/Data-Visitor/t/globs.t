#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Visitor;

our ( $FOO, %FOO );

my $glob = \*FOO;

$FOO = 3;
%FOO = ( foo => "bar" );
is( ${ *$glob{SCALAR} }, 3, "scalar glob created correctly" );
is_deeply( *$glob{HASH}, { foo => "bar" }, "hash glob created correctly" );

my $structure = [ $glob ];

my $mock;
my %called;

{
    my $meta = Class::MOP::class_of('Data::Visitor');

    my $class;
    $class = $meta->create_anon_class(
        superclasses => [$meta->name],
        methods => {
            meta => sub { $class },
            map {
                my $e = $_;
                ($e => sub { $called{$e}++; shift->${\"Data::Visitor::$e"}(@_) })
            } map { "visit_$_" } qw(hash glob value array)
        },
    );

    $mock = $class->name->new;
}

%called = ();
my $mapped = $mock->visit( $structure );

# structure sanity
is( ref $mapped, "ARRAY", "container" );
is( ref ( $mapped->[0] ), "GLOB", "glob ref" );
is( ${ *{$mapped->[0]}{SCALAR} }, 3, "value in glob's scalar slot");

ok($called{visit_array});
ok($called{visit_glob});
ok($called{visit_value});
ok($called{visit_hash});

done_testing;
