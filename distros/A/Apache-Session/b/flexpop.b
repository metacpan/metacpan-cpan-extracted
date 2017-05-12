use Apache::Session::Flex;
use Benchmark;

$hashref = {
	args => {
		Store => 'DBI',
		Lock  => 'Semaphore',
		Generate => 'MD5',
		Serialize => 'Storable',
	}
};

sub foo {
	Apache::Session::Flex::populate($hashref);
}

timethis(-10, \&foo, 'Construct 100K');
