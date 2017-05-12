use Test;
use Chart::Sequence::Object;
use strict;

my $b;

my @tests = (
sub {
    $b = Chart::Sequence::Object->new;

    ok UNIVERSAL::isa( $b, "Chart::Sequence::Object" );
},

sub {
    $b->name( "Foo" );
    ok $b->name, "Foo", "name";
},

);

plan tests => 0+@tests;

$_->() for @tests;
