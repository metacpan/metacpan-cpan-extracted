use warnings;
use strict;

BEGIN {
	unless("$]" >= 5.007001) {
		require Test::More;
		Test::More::plan(skip_all => "can't capture output");
	}
}

use Test::More tests => 6;

use App::olson ();

my $stdout = "";
close STDOUT;
open(STDOUT, ">", \$stdout) or die;
App::olson::run("version");

like $stdout, qr/^    \Q$_\E [0-9]+\.[0-9]+$/m foreach qw(
	App::olson
	DateTime::TimeZone::Olson
	DateTime::TimeZone::SystemV
	DateTime::TimeZone::Tzfile
	Time::OlsonTZ::Data
);

like $stdout, qr/^Olson database: [0-9]{4}[a-z]$/m;

1;
