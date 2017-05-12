use Test::More;

use lib qw(t/lib);


use HTTP::Request::Common qw(GET HEAD PUT DELETE POST);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->get_ok('/recorder/start', 'start recorder');

my $request = POST '/foo?foo=bar', [ foo => 'get index' ];
$request->method('POST');
$mech->request( $request );

my $url = URI->new('/foo');
$url->query_form( { 'foo' => 'bar' } );
$request = POST $url, [ name => 'bar', password => 'foo' ];
$request->method('PUT');
$response = $mech->request($request);

$request = GET '/foo';
$response = $mech->request($request);

$request = GET '/code304';
$response = $mech->request($request);

$request = DELETE '/foo';
$response = $mech->request($request);

$mech->get_ok('/recorder/stop', 'stop recorder');

subtest 'run generated tests' => sub { 
    plan tests => 5;
    my $content = $mech->content;
    $content =~ s/done_testing;//s;
    eval $content;
};

done_testing;