use strict;
use warnings;
use Test::More;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use Test::Rest;

use_ok 'Catalyst::Test', 'Test::Serialize';

my $t = Test::Rest->new('content_type' => 'text/my-csv');

my $has_serializer = eval "require XML::Simple";

    my $monkey_template = {
        monkey => 'likes chicken!',
    };
    my $mres = request($t->get(url => '/monkey_get'));
    ok( $mres->is_success, 'GET the monkey succeeded' );
    my $output = { split( /,/, $mres->content ) };
    is_deeply($output, $monkey_template, "GET returned the right data");

    my $post_data = {
        'sushi' => 'is good for monkey',
    };
    my $mres_post = request( $t->post( url => '/monkey_put', data => join( ',', %$post_data ) ) );
    ok( $mres_post->is_success, "POST to the monkey succeeded");
    is_deeply($mres_post->content, "is good for monkey", "POST data matches");

1;

done_testing;
