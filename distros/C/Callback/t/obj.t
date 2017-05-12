
use Callback;

eval "require Storable";
if ($@) {
	print "1..0\n";
	exit 0;
}

print "1..5\n";

my $c = 1;

Storable->import(qw(freeze thaw));

package TEST;

sub make { bless {}, shift }

sub print {
	my $self = shift;
	my $d = 0;
	for my $x (@_) {
		$d += $x;
	}
	print ($c == $d ? "ok $d\n" : "not ok $c\n");
	$c++;
}

package main;

my $obj = TEST->make;
my $c5 = new Callback ($obj, 'print');
$c5->call(1);

my $c2 = new Callback ($obj, 'print', 2);
$c2->call;

my $c3a = new Callback ($obj, 'print', 3);
my $c3b = new Callback $c3a;
$c3b->call;

my $c4 = new Callback ($c3a, 1);
$c4->call;

$c4->call(1);

