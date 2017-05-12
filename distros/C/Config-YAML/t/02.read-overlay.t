use Test::More no_plan;
use Config::YAML;

my $c = Config::YAML->new(config => 't/test.yaml');

ok($c->{clobber} == 1, "This should always work if the previous tests did");

$c->read('t/test2.yaml');

ok($c->{clobber} == 2, "Reassignment from secondary conf ok");
ok($c->{nuval} == 1, "Assignment from secondary conf ok");
ok($c->{media}[0] eq 'ogg');
ok($c->{media}[1] eq 'mp3');
ok(!(defined $c->{media}[2]), "Array (re)assignment from secondary conf ok");
