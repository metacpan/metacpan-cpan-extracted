use Dwarf::Pragma utf8 => 0;
use Dwarf;
use Encode;
use Test::More 0.88;

sub c {
	my %additional_env = @_;

	my $env = {
		'SCRIPT_NAME'       => '/dwarf/test/api/ping.json',
		'SERVER_NAME'       => 'perl.org',
		'HTTP_CONNECTION'   => 'TE, close',
		'REQUEST_METHOD'    => 'GET',
		'SCRIPT_URI'        => 'http://www.perl.org/dwarf/test/api/ping.json',
		'SCRIPT_FILENAME'   => '/dwarf/test/api/ping.json',
		'SERVER_SOFTWARE'   => 'Apache/1.3.27 (Unix) ',
		'HTTP_TE'           => 'deflate,gzip;q=0.3',
		'QUERY_STRING'      => 'hoge=あいうえお&name[]=hoge&name[1]=fuga',
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

	for my $k (keys %additional_env) {
		$env->{$k} = $additional_env{$k};
	}

	my $c = Dwarf->new(env => $env);
	$c->request_handler_prefix('');

	return $c;
}

subtest "Decode parameters" => sub {
	my $c = c(
	);

	my $hoge = $c->param('hoge');
	ok Encode::is_utf8($hoge), 'parameters are decoded';
};

subtest "ARRAY parameters" => sub {
	my $c = c(
	);
	my $name = $c->param('name[]');
	is ref $name, 'ARRAY', 'name[] param is ARRAY REF';
	is @$name, 2, 'name[] param have 2 values in scalar context';

	my @name_arr = $c->param('name[]');
	is @name_arr, 1, 'parameters have only 1 value in array context';
};

done_testing();
