#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Visitor;

can_ok('Data::Visitor', "new");
isa_ok(my $o = Data::Visitor->new, 'Data::Visitor');

can_ok( $o, "visit" );

my @things = ( "foo", 1, undef, 0, {}, [], do { my $x = "blah"; \$x }, bless({}, "Some::Class") );

$o->visit($_) for @things; # no explosions in void context

is_deeply( $o->visit( $_ ), $_, "visit returns value unlatered" ) for @things;

can_ok( $o, "visit_value" );
can_ok( $o, "visit_object" );
can_ok( $o, "visit_hash" );
can_ok( $o, "visit_array" );


my $mock;
my %called;

{
    my $meta = Class::MOP::class_of($o);

    my $class;
    $class = $meta->create_anon_class(
        superclasses => [$meta->name],
        methods      => {
            meta => sub { $class },
            map {
                my $e = $_;
                ($e->[0] => sub { $called{ $e->[0] }++; $e->[1]->(@_) })
            } (
                [ visit_value    => sub { 'magic' } ],
                [ visit_object   => sub { 'magic' } ],
                [ visit_hash_key => sub { $_[1] } ],
                [ visit_hash     => sub { shift->Data::Visitor::visit_hash(@_) } ],
                [ visit_array    => sub { shift->Data::Visitor::visit_array(@_) } ],
            )
        },
    );

    $mock = $class->rebless_instance($o);
}


# cause logging
%called = ();
$mock->visit( "foo" );
ok($called{visit_value});

%called = ();
$mock->visit( 1 );
ok($called{visit_value});

%called = ();
$mock->visit( undef );
ok($called{visit_value});

%called = ();
$mock->visit( [ ] );
ok($called{visit_array});
ok(!$called{visit_value}, "visit_value not called");

%called = ();
$mock->visit( [ "foo" ] );
ok($called{visit_array});
ok($called{visit_value});

%called = ();
$mock->visit( "foo" );
ok($called{visit_value});

%called = ();
$mock->visit( {} );
ok($called{visit_hash});
ok(!$called{visit_value}, "visit_value not called");

%called = ();
$mock->visit( { foo => "bar" } );
ok($called{visit_hash});
ok($called{visit_value});

%called = ();
$mock->visit( bless {}, "Foo" );
ok($called{visit_object});

is_deeply( $mock->visit( undef ), "magic", "fmap behavior on value" );
is_deeply( $mock->visit( { foo => "bar" } ), { foo => "magic" }, "fmap behavior on hash" );
is_deeply( $mock->visit( [qw/la di da/]), [qw/magic magic magic/], "fmap behavior on array" );

done_testing;
