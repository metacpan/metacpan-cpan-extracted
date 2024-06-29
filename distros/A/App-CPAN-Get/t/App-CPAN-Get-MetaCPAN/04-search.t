use strict;
use warnings;

use App::CPAN::Get::MetaCPAN;
use English;
use Error::Pure::Utils qw(clean);
use HTTP::Response;
use Test::LWP::UserAgent;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $user_agent = Test::LWP::UserAgent->new;
my $content = <<'END';
{
   "release" : "App-CPAN-Search-0.09",
   "checksum_sha256" : "7239ce1154a4002b9b461e5ad80a50ac21b9477b7f000a6a89f924e546e7a63d",
   "version" : "0.09",
   "status" : "latest",
   "date" : "2023-01-23T17:24:56",
   "download_url" : "https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-CPAN-Search-0.09.tar.gz",
   "checksum_md5" : "798a40ee72e0078a8f960186d94eb4b4"
}
END
$user_agent->map_response(
	qr(https://fastapi\.metacpan\.org/v1/download_url/App::CPAN::Search),
	HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json; charset=utf-8'], $content),
);
my $obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => $user_agent,
);
my $ret_hr = $obj->search({
	'package' => 'App::CPAN::Search',
});
is_deeply(
	$ret_hr,
	{
		'checksum_md5' => '798a40ee72e0078a8f960186d94eb4b4',
		'checksum_sha256' => '7239ce1154a4002b9b461e5ad80a50ac21b9477b7f000a6a89f924e546e7a63d',
		'date' => '2023-01-23T17:24:56',
		'download_url' => 'https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-CPAN-Search-0.09.tar.gz',
		'release' => 'App-CPAN-Search-0.09',
		'status' => 'latest',
		'version' => '0.09',
	},
	'Returned structure (with package).',
);

# Test.
$user_agent = Test::LWP::UserAgent->new;
$content = <<'END';
{
   "release" : "App-CPAN-Search-0.08",
   "checksum_sha256" : "93a5d68aade2dedcf1a2673789f5e84041844dc623d077af8937c3a10377bcb3",
   "version" : "0.08",
   "status" : "cpan",
   "date" : "2022-05-04T13:02:09",
   "download_url" : "https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-CPAN-Search-0.08.tar.gz",
   "checksum_md5" : "2cbadf113bd23e93e64dcdac3962e123"
}
END
$user_agent->map_response(
	qr(https://fastapi\.metacpan\.org/v1/download_url/App::CPAN::Search),
	HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json; charset=utf-8'], $content),
);
$obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => $user_agent,
);
$ret_hr = $obj->search({
	'package' => 'App::CPAN::Search',
	'version' => '0.08',
});
is_deeply(
	$ret_hr,
	{
		'checksum_md5' => '2cbadf113bd23e93e64dcdac3962e123',
		'checksum_sha256' => '93a5d68aade2dedcf1a2673789f5e84041844dc623d077af8937c3a10377bcb3',
		'date' => '2022-05-04T13:02:09',
		'download_url' => 'https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-CPAN-Search-0.08.tar.gz',
		'release' => 'App-CPAN-Search-0.08',
		'status' => 'cpan',
		'version' => '0.08',
	},
	'Returned structure (with package and version).',
);

# Test.
$obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => Test::LWP::UserAgent->new,
);
eval {
	$obj->search;
};
is($EVAL_ERROR, "Bad search options.\n",
	"Bad search options (no arg to search).");
clean();

# Test.
$obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => Test::LWP::UserAgent->new,
);
eval {
	$obj->search('');
};
is($EVAL_ERROR, "Bad search options.\n",
	"Bad search options ('').");
clean();

# Test.
$obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => Test::LWP::UserAgent->new,
);
eval {
	$obj->search({});
};
is($EVAL_ERROR, "Package doesn't present.\n",
	"Package doesn't present (no 'package' key).");
clean();

# Test.
$obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => Test::LWP::UserAgent->new,
);
eval {
	$obj->search({
		'package' => 'App::CPAN::Get',
	});
};
is($EVAL_ERROR, "Module 'App::CPAN::Get' doesn't exist.\n",
	"Module 'App::CPAN::Get' doesn't exist.");
clean();
