use strict;
use warnings;
use Test::More;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use Test::Rest;

use_ok 'Catalyst::Test', 'Test::Serialize';

# Should use the default serializer, YAML
my $t = Test::Rest->new('content_type' => 'text/x-yaml');

my $has_serializer = eval "require YAML::Syck";
SKIP: {
    skip "YAML::Syck not available", 4, unless $has_serializer;

    # We should use the default serializer, YAML
    my $monkey_template = {
        monkey => 'likes chicken!',
    };
    my $mres = request($t->get(url => '/monkey_get'));
    ok( $mres->is_success, 'GET the monkey succeeded' );
    is_deeply(YAML::Syck::Load($mres->content), $monkey_template, "GET returned the right data");

    my $post_data = {
        'sushi' => 'is good for monkey',
    };
    my $mres_post = request($t->post(url => '/monkey_put', data => YAML::Syck::Dump($post_data)));
    ok( $mres_post->is_success, "POST to the monkey succeeded");
    is_deeply($mres_post->content, "is good for monkey", "POST data matches");
};

1;

done_testing;
