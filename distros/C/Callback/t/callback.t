
use Callback;

print "1..7\n";

package TEST;

sub make { bless {}, shift }

sub pr6 {
	my $self = shift;
	my ($d) = @_;
	print "ok $d\n";
}

package main;

my $c0 = new Callback (\&pr0);
my $c1 = new Callback (\&pr1, 2);
my $c2 = new Callback (\&pr1, 3);
my $c3 = new Callback (\&pr1);
my $c4 = new Callback (\&pr2, 1);

my $obj = TEST->make;
my $c5 = new Callback ($obj, 'pr6', 6);
my $c6 = new Callback ($obj, 'pr6');

$c0->call();
$c1->call();
$c2->call(5);
$c3->call(4);
$c4->call(4);
$c5->call();
$c6->call(7);

sub pr0 
{
	print "ok 1\n";
}

sub pr1
{
	my ($a) = @_;
	print "ok $a\n";
}

sub pr2
{
	my ($a, $b) = @_;
	my $s = $a + $b;
	print "ok $s\n";
}

