use Dwarf::Pragma;
use Dwarf::Validator;
use Dwarf::Request;
use Data::Dumper;
use Test::More 0.88;

my $q = do {
	my $file = 't/00_dwarf/file/post_data.txt';
	open my $fh, "<", $file
	  or die "missing test file $file";
	binmode $fh;
	my $env = {
		'SCRIPT_NAME'       => '/dwarf/test/api/ping.json',
		'SERVER_NAME'       => 'perl.org',
		'HTTP_CONNECTION'   => 'TE, close',
		'REQUEST_METHOD'    => 'GET',
		'SCRIPT_URI'        => 'http://www.perl.org/dwarf/test/api/ping.json',
		'SCRIPT_FILENAME'   => '/dwarf/test/api/ping.json',
		'SERVER_SOFTWARE'   => 'Apache/1.3.27 (Unix) ',
		'HTTP_TE'           => 'deflate,gzip;q=0.3',
		'QUERY_STRING'      => 'name[]=1&name[1]=2',
		'REMOTE_PORT'       => '1855',
		'HTTP_USER_AGENT'   => 'Mozilla/5.0 (Linux; U; Android 4.0.1; ja-jp; Galaxy Nexus Build/ITL41D) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30',
		'SERVER_PORT'       => '80',
		'REMOTE_ADDR'       => '127.0.0.1',
		'CONTENT_TYPE'      => 'application/x-www-form-urlencoded',
		'SERVER_PROTOCOL'   => 'HTTP/1.1',
		'PATH'              => '/usr/local/bin:/usr/bin:/bin',
		'PATH_INFO'         => '/dwarf/test/api/ping.json',
		'REQUEST_URI'       => '/dwarf/test/api/ping.json',
		'GATEWAY_INTERFACE' => 'CGI/1.1',
		'SCRIPT_URL'        => '/dwarf/test/api/ping.json',
		'SERVER_ADDR'       => '127.0.0.1',
		'DOCUMENT_ROOT'     => '/home/develop',
		'HTTP_HOST'         => 'www.perl.org'
	};
	Dwarf::Request->new($env);
};

subtest 'ARRAY' => sub {
	my $v = Dwarf::Validator->new($q);
	$v->check(
		'name[]' => [qw/NOT_NULL UINT/],
	);
	ok !$v->has_error;
};

done_testing();
