use strict;
use warnings;
use Test::More;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use Test::Rest;

use_ok 'Catalyst::Test', 'Test::Serialize';

my $t = Test::Rest->new('content_type' => 'text/xml');

my $has_serializer = eval "require XML::Simple";
SKIP: {
    skip "XML::Simple not available", 4, unless $has_serializer;
    
    my $xs = XML::Simple->new('ForceArray' => 0);

    my $monkey_template = {
        monkey => 'likes chicken!',
    };
    my $mres = request($t->get(url => '/monkey_get'));
    ok( $mres->is_success, 'GET the monkey succeeded' );
    my $output = $xs->XMLin($mres->content);
    is_deeply($xs->XMLin($mres->content)->{'data'}, $monkey_template, "GET returned the right data");

    my $post_data = {
        'sushi' => 'is good for monkey',
    };
    my $mres_post = request($t->post(url => '/monkey_put', data => $xs->XMLout($post_data)));
    ok( $mres_post->is_success, "POST to the monkey succeeded");
    is_deeply($mres_post->content, "is good for monkey", "POST data matches");
};

1;

done_testing;
