use Test::More tests => 6;
use Test::Exception;
BEGIN { use_ok('Acme::What') };

{
	use Acme::What '+Test::More::ok';
	
	what 1
	what 2; 0;
	what 3;
}

{
	use Acme::What 'passit';
	sub passit { ok @_ }
	
	my $i_am_going_to_give_you = what 4
	
	throws_ok {
		no Acme::What;
		what now?
		} qr{Acme::What};
}

