
use Callback;

print "1..2\n";

package TEST;

sub make { bless {}, shift }

sub print {
	my $self = shift;
	my ($d) = @_;
	print "ok $d\n";
}

package main;

my $obj = TEST->make;
my $c = new Callback ($obj, 'print', 1);

$c->call();

eval { $c = new Callback ($obj, 'no_such_method', 2) };
print "not " unless $@ =~ /\bno_such_method\b/;
print "ok 2\n";

