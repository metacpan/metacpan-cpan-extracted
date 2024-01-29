use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Jena::Fuseki;
use Env qw(@PATH);

alien_diag 'Alien::Jena::Fuseki';
alien_ok 'Alien::Jena::Fuseki';

push @PATH, Alien::Jena::Fuseki->dist_dir if Alien::Jena::Fuseki->install_type eq 'share';

my $fuseki_server = $^O ne 'MSWin32' ? 'fuseki-server' : 'fuseki-server.bat';
run_ok([ $fuseki_server, '--version' ])
  ->success
  ->out_like(qr/Apache Jena Fuseki version ([0-9\.]+)/);

done_testing;
