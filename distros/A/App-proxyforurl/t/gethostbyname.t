use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::File qw(path);

my $script = path(qw(script proxyforurl))->to_abs;
plan skip_all => 'script/proxyforurl not found' unless -r $script;
my $t = Test::Mojo->new($script);

$t->get_ok('/gethostbyname')->status_is(400)->content_is('Host missing.');
$t->get_ok('/gethostbyname?host=localhost')->status_is(200)->content_like(qr{\w+[:\.]});
$t->get_ok('/gethostbyname?host=i.do.not.think.this.domain.exists')->status_is(400);

local $TODO = 'Not sure how to make this reliable';
$t->content_is('No IP found for i.do.not.think.this.domain.exists.');

done_testing;
