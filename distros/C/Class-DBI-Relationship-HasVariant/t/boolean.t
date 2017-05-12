use Test::More;

use strict;
use warnings;

BEGIN { 
	eval 'use DBD::SQLite 1.0 ()';
	plan skip_all => "DBD::SQLite required to run this test" if $@;

	plan tests => 8;

	use lib 't/lib';

	use_ok("Test::CDBI::Variant");

}

Test::CDBI::Variant::get_pristene_db;

{
	my $boolean = Boolean::Stored->retrieve(1);
	cmp_ok($boolean->boolean, '==', 0, "boolean 1: false");
}


{
	my $boolean = Boolean::Stored->retrieve(2);
	cmp_ok($boolean->boolean, '==', 1, "boolean 2: true");
}

{
	my $boolean = Boolean::Stored->retrieve(3);
	is($boolean->boolean,    undef, "boolean 3: undef");
}

{
	my $boolean = Boolean::Stored->find_or_create({ bid => 4, boolean => 0});
	$boolean->update;
	cmp_ok($boolean->boolean, '==', 0, "boolean 4: false");
}

{
	my $boolean = Boolean::Stored->find_or_create({ bid => 5, boolean => 1});
	cmp_ok($boolean->boolean, '==', 1, "boolean 5: true");
}

{
	my $boolean = Boolean::Stored->find_or_create({ bid => 6, boolean => undef});
	    is($boolean->boolean,   undef, "boolean 6: undef");
}

{
	my $boolean = Boolean::Stored->find_or_create({ bid => 7, boolean => "0E0"});
	    is($boolean->boolean,   undef, "boolean 7: undef");
}

