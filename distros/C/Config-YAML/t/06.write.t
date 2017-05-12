use Test::More tests => 1;
use Config::YAML;

my $c = Config::YAML->new( config => 't/test.yaml',
                           output => 't/test.out'
                         );
$c->write;

my $d = Config::YAML->new( config => 't/test.out');
ok($c->{media}[4] eq $d->{media}[4], "YAML output is working");
unlink 't/test.out';