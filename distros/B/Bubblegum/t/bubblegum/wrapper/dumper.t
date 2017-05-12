use Bubblegum::Wrapper::Dumper;
use Test::More;

can_ok 'Bubblegum::Wrapper::Dumper', 'new';
can_ok 'Bubblegum::Wrapper::Dumper', 'data';
can_ok 'Bubblegum::Wrapper::Dumper', 'encode';
can_ok 'Bubblegum::Wrapper::Dumper', 'decode';

my $dump1 = Bubblegum::Wrapper::Dumper->new(
    data => {1..4}
);

is $dump1->encode, "{'1' => 2,'3' => 4}",
    'encode returns the correct string';

my $dump2 = Bubblegum::Wrapper::Dumper->new(
    data => "{'1' => 2,'3' => 4}"
);

is_deeply $dump2->decode, {'1' => 2,'3' => 4},
    'decode generates the correct hashref';

done_testing;
