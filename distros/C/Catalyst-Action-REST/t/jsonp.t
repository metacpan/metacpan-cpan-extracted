use strict;
use warnings;
use Test::More;
use FindBin;
use JSON::MaybeXS;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use Test::Rest;
use utf8;

use_ok 'Catalyst::Test', 'Test::Serialize', 'Catalyst::Action::Serialize::JSON';

my $json = JSON->new->utf8;

for ('text/javascript','application/x-javascript','application/javascript') {
    my $t = Test::Rest->new('content_type' => $_);
    my $monkey_template = { monkey => 'likes chicken!' };

    my $mres = request($t->get(url => '/monkey_get?callback=My_Animal.omnivore'));
    ok( $mres->is_success, 'GET the monkey succeeded' );

    my ($json_param) = $mres->content =~ /^My_Animal.omnivore\((.*)?\);$/;
    is_deeply($json->decode($json_param), $monkey_template, "GET returned the right data");
}

1;

done_testing;
