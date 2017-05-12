use Apache::Gallery;
my $tests;
BEGIN {
	$tests=8;
	eval { require Test::MockObject };
	if ($@) {
		print("1..$tests\n");
		for (1..$tests) {
			print ("ok $_ # skip Test::MockObject not found\n");
		}
		exit 0;
	}
}
use Test::More tests => $tests;
use File::Spec;

# Test these cases:
# +--------------------------------------------------+
# | No. | GalleryCacheDir | Virtual | Strip Filename |
# |  1  |      undef      |    y    |       y        |
# |  2  |      undef      |    y    |       n        |
# |  3  |      undef      |    n    |       y        |
# |  4  |      undef      |    n    |       n        |
# |  5  |  't/cachetest'  |    y    |       y        |
# |  6  |  't/cachetest'  |    y    |       n        |
# |  7  |  't/cachetest'  |    n    |       y        |
# |  8  |  't/cachetest'  |    n    |       n        |
# +-----+-----------------+---------+----------------+

sub request {
	my ($cachedir, $virtual) = @_;
	my $r=Test::MockObject->new();
	$r->set_always('location', '/location');
	$r->set_always('uri', '/uripath1/uripath2/urifile');
	$r->set_always('dir_config', $cachedir);
	my $server=Test::MockObject->new();
	$server->set_always('is_virtual', $virtual);
	$server->set_always('server_hostname', 'hostname' );
	$r->set_always('server', $server);

	return $r;
}

my $r=request(undef, 1);
is(Apache::Gallery::cache_dir($r, 1), '/var/tmp/Apache-Gallery/hostname/uripath1/uripath2');
is(Apache::Gallery::cache_dir($r, 0), '/var/tmp/Apache-Gallery/hostname/uripath1/uripath2/urifile');

$r=request(undef, 0);
is(Apache::Gallery::cache_dir($r, 1), '/var/tmp/Apache-Gallery/location/uripath1/uripath2');
is(Apache::Gallery::cache_dir($r, 0), '/var/tmp/Apache-Gallery/location/uripath1/uripath2/urifile');

$r=request('t/cachetest', 1);
is(Apache::Gallery::cache_dir($r, 1), 't/cachetest/uripath1/uripath2');
is(Apache::Gallery::cache_dir($r, 0), 't/cachetest/uripath1/uripath2/urifile');

$r=request('t/cachetest', 0);
is(Apache::Gallery::cache_dir($r, 1), 't/cachetest/uripath1/uripath2');
is(Apache::Gallery::cache_dir($r, 0), 't/cachetest/uripath1/uripath2/urifile');
