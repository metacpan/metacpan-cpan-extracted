use Dwarf::Pragma;
use JSON;
use Test::More 0.88;

subtest "boolean" => sub {
	ok true;
	ok !false;
	ok (1 == 1);
	ok !(1 == 0);

	my $json = JSON->new->convert_blessed;
	my $encoded = $json->encode({ false => false, true => true });
	my $decoded = $json->decode($encoded);
	#is $encoded, '{"false":false,"true":true}';
};

done_testing();
