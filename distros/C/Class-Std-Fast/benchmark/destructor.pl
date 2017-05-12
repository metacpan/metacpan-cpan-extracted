use lib '../lib';
use Benchmark;
my @list;

package MyBenchTestFastBasic;
use Class::Std::Fast constructor => 'basic', isa_unsorted => 1;

my %one_of :ATTR(:name<one> :default<()>);
my %two_of :ATTR(:name<two> :default<()>);
my %three_of :ATTR(:name<three> :default<()>);
my %four_of :ATTR(:name<four> :default<()>);

Class::Std::initialize;

1;

package MyBenchTestFast;
use Class::Std::Fast;

my %one_of :ATTR(:name<one> :default<()>);
my %two_of :ATTR(:name<two> :default<()>);
my %three_of :ATTR(:name<three> :default<()>);
my %four_of :ATTR(:name<four> :default<()>);

Class::Std::initialize;

1;

package MyBenchTest;
use Class::Std;

my %one_of :ATTR(:name<one> :default<()>);
my %two_of :ATTR(:name<two> :default<()>);
my %three_of :ATTR(:name<three> :default<()>);
my %four_of :ATTR(:name<four> :default<()>);

Class::Std::initialize;
1;

package MyBenchTestFastCache;
use base qw(MyBenchTest);
use Class::Std::Fast constructor => 'basic', cache => 1, unsorted_isa => 1;

my %one_of :ATTR(:name<one>);
my %two_of :ATTR(:name<two>);
my %three_of :ATTR(:name<three>);
my %four_of :ATTR(:name<four>);
Class::Std::initialize;
1;


package main;

my $n = 100;
my $n = 5;
timethis $n, sub {
    for my $class ('MyBenchTestFastBasic') {
        push @list,  $class->new({ one => 'foo', two => 'bar'}) for (1..5000);
        undef @list
    };
};
