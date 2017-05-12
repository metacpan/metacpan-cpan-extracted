use strict;
use warnings;
use Test::More;
use FindBin;
use JSON::MaybeXS;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use Test::Rest;
use utf8;

use_ok 'Catalyst::Test', 'Test::Serialize';

my $json = JSON->new->utf8;
# The text/x-json should throw a warning
for ('text/x-json', 'application/json') {
    my $t = Test::Rest->new('content_type' => $_);
    my $monkey_template = {
        monkey => 'likes chicken!',
    };
    my $mres = request($t->get(url => '/monkey_get'));
    ok( $mres->is_success, 'GET the monkey succeeded' );
    is_deeply($json->decode($mres->content), $monkey_template, "GET returned the right data");

    my $post_data = {
        'sushi' => 'is good for monkey',
        'chicken' => ' 佐藤 純',
    };
    my $mres_post = request($t->post(url => '/monkey_put', data => $json->encode($post_data)));
    ok( $mres_post->is_success, "POST to the monkey succeeded");
    my $exp = "is good for monkey 佐藤 純";
    utf8::encode($exp);
    is_deeply($mres_post->content, $exp, "POST data matches");
}

{
    my $t = Test::Rest->new('content_type' => 'application/json');
    my $json_data = '{ "sushi":"is good for monkey", }';
    my $mres_post = request($t->post(url => '/monkey_put', data => $json_data));
    ok( ! $mres_post->is_success, "Got expected failed status due to invalid JSON" );

    my $relaxed_post = request( $t->post(url => "/monkey_json_put", data => $json_data));
    ok( $relaxed_post->is_success, "Got success due to setting relaxed JSON input" );
}

1;

done_testing;
