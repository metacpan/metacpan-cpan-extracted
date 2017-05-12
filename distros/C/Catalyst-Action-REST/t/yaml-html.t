use strict;
use warnings;
use Test::More;
use Test::Requires qw(YAML::Syck);
use YAML::Syck;
use FindBin;

use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );
use Test::Rest;

BEGIN {
    use_ok 'Catalyst::Test', 'Test::Serialize';
}

my $has_serializer = eval "require YAML::Syck";
SKIP: {
    skip "YAML::Syck not available", 3, unless $has_serializer;

    my $t = Test::Rest->new( 'content_type' => 'text/html' );

    my $monkey_template =
"<html><title>Test::Serialize</title><body><pre>--- \nmonkey: likes chicken!\n</pre></body></html>";
    my $mres = request( $t->get( url => '/monkey_get' ) );
    ok( $mres->is_success, 'GET the monkey succeeded' );
    is( $mres->content, $monkey_template, "GET returned the right data" );

    my $post_data = { 'sushi' => 'is good for monkey', };
    my $mres_post =
      request( $t->post( url => '/monkey_put', data => Dump($post_data) ) );
    ok( $mres_post->is_error, "POST to the monkey failed; no deserializer." );

    # xss test - RT 63537
    my $xss_template =
"<html><title>Test::Serialize</title><body><pre>--- \nmonkey: likes chicken &gt; sushi!\n</pre></body></html>";
    my $xres = request( $t->get( url => '/xss_get' ) );
    ok( $xres->is_success, 'GET the xss succeeded' );
    is( $xres->content, $xss_template, "GET returned the right data" );


}
1;

done_testing;
