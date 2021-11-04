use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::File qw(path);

my $script = path(qw(script proxyforurl))->to_abs;
plan skip_all => 'script/proxyforurl not found' unless -r $script;
my $t = Test::Mojo->new($script);

subtest 'invalid input' => sub {
  $t->get_ok('/gethostbyname')->status_is(400)->content_is('Host missing.');
};

subtest 'known host' => sub {
  $t->get_ok('/gethostbyname?host=localhost')->status_is(200)->content_like(qr{\w+[:\.]});
};

subtest 'unknown host' => sub {
  local $TODO = 'CPAN smokers resolve this name to the smoker hostname..?';
  $t->get_ok('/gethostbyname?host=i.do.not.think.this.domain.exists')->status_is(400)
    ->content_like(qr{No IP found});
};

done_testing;
