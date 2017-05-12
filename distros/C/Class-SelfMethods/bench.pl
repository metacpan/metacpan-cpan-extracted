use Benchmark;
use Class::SelfMethods;

package CSM::Foo;
@ISA = qw(Class::SelfMethods);

sub _friendly {
  return 'foo';
}

package main;

my $foo = CSM::Foo->new(name => 'foo');

print "\nDirect call on a method (for comparison):\n  ";
timethis(100_000, sub {$foo->_friendly});

print "\nInstance Attribute:\n  ";
$foo->name;
timethis(100_000, sub {$foo->name});

print "\nInherited Method:\n  ";
$foo->friendly;
timethis(100_000, sub {$foo->friendly});

print "\nInstance Method:\n  ";
$foo->friendly_SET(sub {return 'foo';});
timethis(100_000, sub {$foo->friendly});

print "\nAccessor (_SET):\n  ";
timethis(100_000, sub {$foo->friendly_SET('foo')});

print "\nAccessor (_SET) not in symbol table (10,000 iters):\n   ";
$demo = "A";
timethis(10_000, sub {$temp = "${demo}_SET"; $foo->$temp('foo'); $demo++});

print "\nInstance Attribute not in symbol table (10,000 iters):\n   ";
$demo = "A";
timethis(10_000, sub {$foo->$demo(); $demo++});
