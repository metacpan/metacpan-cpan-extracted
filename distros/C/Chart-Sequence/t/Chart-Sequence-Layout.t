use Test;
use Chart::Sequence::Layout;
use Chart::Sequence;
use strict;

my $l;

my @tests = (
sub {
    $l = Chart::Sequence::Layout->new;
    ok $l->isa( "Chart::Sequence::Layout" );
},

sub {
    my $s = Chart::Sequence->new(
        Name => "Sequence 1",
        Messages => [
            [ "Foo" => "Bar" ],
            [ "Baz" => "Bat" ],
        ],
    );

#TODO:    $l->lay_out( $s );
    ok $s;
},

);

plan tests => 0+@tests;

$_->() for @tests;
