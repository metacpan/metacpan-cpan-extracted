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
		'psgi.input'        => $fh,
		'SCRIPT_NAME'       => '/test.cgi',
		'SERVER_NAME'       => 'perl.org',
		'HTTP_CONNECTION'   => 'TE, close',
		'REQUEST_METHOD'    => 'POST',
		'SCRIPT_URI'        => 'http://www.perl.org/test.cgi',
		'CONTENT_LENGTH'    => 3460,
		'SCRIPT_FILENAME'   => '/home/usr/test.cgi',
		'SERVER_SOFTWARE'   => 'Apache/1.3.27 (Unix) ',
		'HTTP_TE'           => 'deflate,gzip;q=0.3',
		'QUERY_STRING'      => '',
		'REMOTE_PORT'       => '1855',
		'HTTP_USER_AGENT'   => 'Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)',
		'SERVER_PORT'       => '80',
		'REMOTE_ADDR'       => '127.0.0.1',
		'CONTENT_TYPE'      => 'multipart/form-data; boundary=xYzZY',
		'SERVER_PROTOCOL'   => 'HTTP/1.1',
		'PATH'              => '/usr/local/bin:/usr/bin:/bin',
		'REQUEST_URI'       => '/test.cgi',
		'GATEWAY_INTERFACE' => 'CGI/1.1',
		'SCRIPT_URL'        => '/test.cgi',
		'SERVER_ADDR'       => '127.0.0.1',
		'DOCUMENT_ROOT'     => '/home/develop',
		'HTTP_HOST'         => 'www.perl.org'
	};
	Dwarf::Request->new($env);
};

subtest 'FILE_MIME' => sub {
	my $v = Dwarf::Validator->new($q);
	$v->check(
		'multiple'       => [qw/NOT_NULL/],
		'300x300_gif[0]' => [qw/FILE_NOT_NULL/, [FILE_MIME => 'image/(gif|jpeg|png)']],
	);
	_dump_error($v);
	ok !$v->has_error;
};

subtest 'FILE_MIME fail' => sub {
	my $v = Dwarf::Validator->new($q);
	$v->check(
		'multiple'       => [qw/NOT_NULL/],
		'300x300_gif[0]' => [qw/FILE_NOT_NULL/, [FILE_MIME => 'image/png']],
	);
	_dump_error($v);
	ok $v->has_error;
};

subtest 'FILE_EXT' => sub {
	my $v = Dwarf::Validator->new($q);
	$v->check(
		'multiple'       => [qw/NOT_NULL/],
		'300x300_gif[0]' => [qw/FILE_NOT_NULL/, [FILE_EXT => 'gif']],
	);
	_dump_error($v);
	ok !$v->has_error;
};

subtest 'FILE_EXT fail' => sub {
	my $v = Dwarf::Validator->new($q);
	$v->check(
		'multiple'       => [qw/NOT_NULL/],
		'300x300_gif[0]' => [qw/FILE_NOT_NULL/, [FILE_EXT => 'png']],
	);
	_dump_error($v);
	ok $v->has_error;
};

sub _dump_error {
	my ($v) = @_;
	if ($v->has_error) {
		while (my ($param, $detail) = each %{ $v->errors }) {
			#warn $param;
			#warn Dumper $detail;
		}
	}
}

done_testing();
