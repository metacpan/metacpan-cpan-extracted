use Apache::Session::DBI;

$hashref = {};

sub foo {
	Apache::Session::DBI::populate($hashref);
}

use Benchmark;

timethis(-10, \&foo, 'Construct 100K');

