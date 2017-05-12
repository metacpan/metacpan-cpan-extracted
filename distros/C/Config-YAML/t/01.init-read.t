use Test::More no_plan;
use Config::YAML;

my $c = Config::YAML->new(config => 't/test.yaml');
can_ok('Config::YAML','new');
isa_ok($c, 'Config::YAML');
ok($c->{_outfile} eq 't/test.yaml', "Implicit output declaration works");
ok($c->{clobber} == 1);
ok($c->{silent} == 0, "Scalar input looks good.");
ok($c->{media}[0] eq 'mp\d');
ok($c->{media}[5] eq 'wmv', "Array input looks good.");

my $d = Config::YAML->new( config => 't/test.yaml',
                           output => '~/.foorc',
                           foo    => 'bar',
                           bar    => 'foo',
                           config => 1,
                           output => 'quux',
                         );
ok($d->{_outfile} eq '~/.foorc', "Explicit output declaration works");
ok($d->{foo} eq 'bar');
ok($d->{bar} eq 'foo', "User config variable declaration works");
ok($d->{config} == 1);
ok($d->{output} eq 'quux', "Double declaration of config/output works");

$_ = 100;
$c = Config::YAML->new( config => '/dev/null' );
ok($_ == 100, "Config::YAML now $_-safe");