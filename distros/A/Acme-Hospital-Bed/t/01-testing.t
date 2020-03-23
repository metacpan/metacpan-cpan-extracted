use Test::More;
use Acme::Hospital::Bed;
BEGIN {
	no warnings 'redefine';
	*Acme::Hospital::Bed::_generate_patient = sub {
		return (
			name => 'Any Name',
			level => 6,
			length => 25
		);
	};
	*Acme::Hospital::Bed::_wait_answer = sub { return 'y' };
}
my $ahb = Acme::Hospital::Bed->new;
$ahb->next_patient(1) for 1..19;
is(scalar @{$ahb->{rooms}}, 19);
is($ahb->{lifes}, 3);
is($ahb->{total_num_of_rooms}, 20);
is($ahb->{max_length_of_stay}, 40);
done_testing();
