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
use Class::Std::Fast constructor => 'basic', cache => 1 , isa_unsorted => 1;

my %one_of :ATTR(:name<one>);
my %two_of :ATTR(:name<two>);
my %three_of :ATTR(:name<three>);
my %four_of :ATTR(:name<four>);
Class::Std::initialize;
1;


package main;
print "Info:
Each test creates an object an stacks two objects into it (two levels)\n";

for my $class ('MyBenchTestFastCache', 'MyBenchTestFastBasic') {
    #, 'MyBenchTestFast', 'MyBenchTest') {
    my $n = 100000;
    print "\n$class ($n iterations - first run)\n";
    timethis $n, sub {
        push @list,  $class->new();
        $list[-1]->set_one($class->new());
        $list[-1]->get_one()->set_two($class->new());
        $list[-1]->get_one();
    };
    print "Cleanup: Destroying ${ \($n *3) } objects\n";
    timethis 1, sub { undef @list };
    print "\n$class ($n iterations - second run)\n";
    timethis $n , sub {
        push @list,  $class->new();
        $list[-1]->set_one($class->new());
        $list[-1]->get_one()->set_two($class->new());
        $list[-1]->get_one();
    };
    print "Cleanup: Destroying ${ \($n *3) } objects\n";
    timethis 1, sub { undef @list };
}


