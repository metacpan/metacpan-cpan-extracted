use strict;
use warnings;
use Test::More;

use App::Aphra;

ok(my $app = App::Aphra->new, 'Got an object');

isa_ok($app, 'App::Aphra');

my %config = (
    source     => 'in',
    fragments  => 'fragments',
    layouts    => 'layouts',
    wrapper    => 'page',
    target     => 'docs',
    output     => 'html',
);

for (keys %config) {
  is($app->config->{$_}, $config{$_}, "Config value $_ is correct");
}

isa_ok($app->template, 'Template');
can_ok($app, qw[run build]);

done_testing;
