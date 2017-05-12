use Capture::Attribute;
use Test::More tests => 10;

sub foo :Capture(STDOUT,STDERR)
{
	warn qq/Compo\n/;
	print q/Radish, lettuce - a couple of weeds/;
	return wantarray ? qw/Mr Bloom/ : q/Mr Bloom/;
}

my ($o, $e) = foo();
is $o, q/Radish, lettuce - a couple of weeds/;
is $e, "Compo\n";

ok(!main->isa('Capture::Attribute'));
ok(!main->can('return'));
can_ok 'Capture::Attribute' => 'return';

ok(Capture::Attribute->return->is_list);
is_deeply(Capture::Attribute->return->value, [qw/Mr Bloom/]);

my $o2 = foo();
is $o2, q/Radish, lettuce - a couple of weeds/;

ok(Capture::Attribute->return->is_scalar);
is(Capture::Attribute->return->value, q/Mr Bloom/);

