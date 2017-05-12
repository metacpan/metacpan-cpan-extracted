use Dwarf::Pragma;
use Dwarf::Util qw/installed/;
use Test::More 0.88;
use FindBin qw($Bin);
use Module::Find;

BEGIN {
	setmoduledirs("$Bin/../../lib");
	for (sort(findallmod("App"))) {
		use_ok($_);
	}
}

done_testing();
