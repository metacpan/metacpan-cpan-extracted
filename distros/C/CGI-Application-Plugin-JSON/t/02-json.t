use Test::More;
use strict;
use CGI;
use JSON::Any;
use lib 't/lib';
use MyApp;

plan(tests => 21);

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

# 1..5
# json_header
{
    my $app = MyBase::MyApp->new( QUERY => CGI->new({ rm => 'test_json' }) );
    my $data = _get_json_data($app);
    is( $data->{foo}, 'blah', 'contains right data for key "foo"' );
    is( $data->{baz}, 'stuff', 'contains right data for key "baz"' );
    ok( ! exists $data->{bar}, 'key "bar" is non-existant' );
}

# 6..12
# add_json_header
{
    my $app = MyBase::MyApp->new( QUERY => CGI->new({ rm => 'test_add' }) );
    my $data = _get_json_data($app);
    is( $data->{foo}, 'blah', 'contains right data for key "foo"' );
    is( $data->{baz}, 'stuff', 'contains right data for key "baz"' );
    is( $data->{bar}, 'more_stuff', 'contains right data for key "bar"' );

    # check the data values
    is( $app->json_header_value('foo'), 'blah', 'json_header_value() using key');
    is_deeply( { $app->json_header_value() }, $data, 'json_header_value() no-key' );
}

# 13
# clear_json_header
{
    my $app = MyBase::MyApp->new( QUERY => CGI->new({ rm => 'test_clear' }) );
    my $output = $app->run();
    my ($json) = ($output =~ /X-JSON: (.*)/i);
    ok(!$json, 'clear_json_header has no X-JSON header');
}

# 14-17
# json_body
{
    my $app = MyBase::MyApp->new( QUERY => CGI->new({ rm => 'test_body' }) );
    my $output = $app->run();
    my ($json) = ($output =~ /X-JSON: (.*)/i);
    ok(!$json, 'json_body has no X-JSON header');
    like($output, qr/Content-type: application\/json/i, 'right content type');
    ($json) = ($output =~ /.*(?={)(.*)/);
    $json = JSON::Any->decode($json);
    ok($json, 'has JSON body');
    is_deeply($json, { foo => 'blah', baz => 'stuff', bar => 'more_stuff'});
}

# 18-21
# json_callback
{
    my $app = MyBase::MyApp->new( QUERY => CGI->new({ rm => 'test_callback' }) );
    my $output = $app->run();
    my ($json) = ($output =~ /X-JSON: (.*)/i);
    ok(!$json, 'json_callback has no X-JSON header');
    like($output, qr/Content-type: text\/javascript/i, 'right content type');
    ($json) = ($output =~ /my_callback\(.*(?={)(.*)\)/);
    $json = JSON::Any->decode($json);
    ok($json, 'has JSON structure');
    is_deeply($json, { foo => 'blah', baz => 'stuff', bar => 'more_stuff'});
}

# has 2 tests
sub _get_json_data {
    my $app = shift;
    my $output = $app->run();
    my ($json) = ($output =~ /X-JSON: (.*)/i);
    ok($json, 'has X-JSON header');
    my $data = JSON::Any->decode($json);
    is( ref $data, 'HASH', 'JSON data is a hash');
    return $data;
}
