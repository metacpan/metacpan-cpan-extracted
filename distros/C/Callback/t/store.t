
use Callback;

eval "require Storable";
if ($@) {
	print "1..0 # Skipped: Storable not installed\n";
	exit 0;
}
unless ($Storable::VERSION >= 2.04) {
	print "1..0 # Skipped: Storable >= 2.04 required\n";
	exit 0;
	my $x = $Storable::VERSION; # used again
}

print "1..5\n";

Storable->import(qw(freeze thaw));

package TEST;

sub make { bless {}, shift }

sub print {
	my $self = shift;
	my ($d) = @_;
	print "ok $d\n";
}

package main;

my $obj = TEST->make;
my $c = new Callback ($obj, 'print');
$c->call(1);

my $x = freeze($c);
print "not " unless defined $x;
print "ok 2\n";

my $c2 = thaw($x);
print "not " unless defined $c2;
print "ok 3\n";

$c2->call(4);

my $c3 = new Callback (\&TEST::print);
eval { $x = freeze($c3) };
print "not " unless $@ =~ /since it contains/;
print "ok 5\n";

