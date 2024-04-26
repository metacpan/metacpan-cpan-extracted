#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper::UnDumper;
plan tests => 6;

package FakeObj;
sub greet { "Hello, " . $_[0]->{name} }

package main;


my $dumper_out = <<'URGH';                                                  
$VAR1 = {
    'foo' => 'bar',
    'shallowref' => $VAR1->{'foo'},
    'cyclref' => $VAR1->{'shallowref'},
    'we' => { 'need' => { 'to' => { 'go' => 'deeper' } } },
    'deepref' => $VAR1->{'we'}{'need'}{'to'}{'go'},
    'objref' => bless( { name => 'Dave' }, 'FakeObj' ),
};
URGH


my $r = Data::Dumper::UnDumper::undumper($dumper_out);

is($r->{foo}, 'bar', "Normal value left alone");
is($r->{shallowref}, 'bar', "Shallow reference resolved");
is($r->{cyclref}, 'bar', "Cyclic ref (ref to a ref) resolved");
is($r->{deepref}, 'deeper', "Deep reference resolved");
isa_ok($r->{objref}, 'FakeObj');
is($r->{objref}->greet, "Hello, Dave", "Object restored correctly");

done_testing;
