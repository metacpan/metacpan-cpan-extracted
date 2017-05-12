use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'touch README.pod' unless -e 'README.pod';

do 'script/proxyforurl' or die $@;
my $t = Test::Mojo->new;

$t->get_ok('/gethostbyname')->status_is(400)->content_is('Host missing.');
$t->get_ok('/gethostbyname?host=localhost')->status_is(200)->content_like(qr{\w+[:\.]});
$t->get_ok('/gethostbyname?host=i.do.not.think.this.domain.exists')->status_is(400);

local $TODO = 'Not sure how to make this reliable';
$t->content_is('No IP found for i.do.not.think.this.domain.exists.');

done_testing;
