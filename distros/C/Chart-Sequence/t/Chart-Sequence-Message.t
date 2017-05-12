use Test;
use Chart::Sequence::Message;
use strict;

my $m;

my @tests = (
sub {
    $m = Chart::Sequence::Message->new( [ "Foo" => "Bar", "Message 0" ] );
    ok $m->isa( "Chart::Sequence::Message" );
},

sub { ok $m->from, "Foo",       "from" },
sub { ok $m->to,   "Bar",       "to"   },
sub { ok $m->name, "Message 0", "name"   },
);

plan tests => 0+@tests;

$_->() for @tests;
