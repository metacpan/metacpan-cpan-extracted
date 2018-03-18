use Dwarf::Pragma;
use Dwarf::Util qw/installed/;
use Test::More 0.88;
use FindBin qw($Bin);
use Module::Find;

my @opts = qw/
	Dwarf::Plugin::Cache::Memcached::Fast
	Dwarf::Plugin::AnyEvent::Redis
	Dwarf::Plugin::CGI::Session
	Dwarf::Plugin::PHP::Session
	Dwarf::Plugin::Text::CSV_XS
/;

setmoduledirs("$Bin/../../lib");

for my $module (sort(findallmod("Dwarf"))) {
	my @list = grep { $module eq $_ } @opts;

	if (@list) {
		my $plugin = $list[0];
		$plugin =~ s/Dwarf::Plugin:://;
		next unless installed($plugin);
	}

	use_ok($module);
}

done_testing();
