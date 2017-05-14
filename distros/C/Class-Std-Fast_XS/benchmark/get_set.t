use strict;

package TestClass_Hash;

sub new { bless $_[1], $_[0]; };

sub get_bla { return shift->{'bla'}; }
sub set_bla { $_[0]->{'bla'} = $_[1]; return $_[0]; }


package TestClass;
use Class::Std::Fast;

my %bla_of :ATTR(:name<bla>);


package TestClass_XS;
use Class::Std::Fast;

require Class::Std::Fast_XS;
my %foo_of :ATTR(:name<bla>);

package main;
use lib '../blib/lib';
use lib '../blib/arch';

use strict;
use warnings;

use Benchmark;

my $hash = TestClass_Hash->new({ bla => 'foo' });
my $obj = TestClass->new({ bla => 'foo'});
my $xs = TestClass_XS->new({ bla => 'foo' });

print "\ngetter\n";
Benchmark::cmpthese 1_000_000, {
    hash => sub { $hash->get_bla() },
    obj => sub { $obj->get_bla() },
    xs => sub { $xs->get_bla() }
};

print "\nsetter\n";
Benchmark::cmpthese 1_000_000, {
    hash => sub { $hash->set_bla('baz') },
    obj => sub { $obj->set_bla('baz') },
    xs => sub { $xs->set_bla('baz') }
}
