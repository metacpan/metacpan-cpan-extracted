use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::Negotiate;

    get '/foo' => sub {
		return choose_variant(
			var1 => {
				Quality => 1.000,
				Type => 'text/html',
				Charset => 'iso-8859-1',
				Language => 'en'
			},
			var2 => {
				Quality => 0.950,
				Type => 'text/plain',
				Charset => 'us-ascii',
				Language => 'no'
			},
		);
	};

}

use Dancer::Test;

my ($R);

$R = dancer_response(GET => '/foo');
is($R->{content} => 'var1');

$R = dancer_response(GET => '/foo', { headers => [ Accept => 'text/plain' ] });
is($R->{content} => 'var2');

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

