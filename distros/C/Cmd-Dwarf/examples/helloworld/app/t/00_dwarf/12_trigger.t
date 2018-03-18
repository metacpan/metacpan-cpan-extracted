use Dwarf::Pragma;
use Dwarf;
use Test::More 0.88;

subtest 'add_trigger' => sub {
	my $c = Dwarf->new;
	$c->add_trigger('before_render', sub {});
	ok @{ $c->{_trigger}->{'before_render'} } == 1;
};

subtest 'get_trigger_code' => sub {
	my $c = Dwarf->new;
	$c->add_trigger('before_render', sub {});
	my @code = $c->get_trigger_code('before_render');
	ok @code == 1;
};

subtest 'call_trigger' => sub {
	my $value = 1;

	my $c = Dwarf->new;
	$c->add_trigger('before_render', sub { $value = 2 });
	$c->call_trigger('before_render');

	is $value, 2;
};

done_testing();
