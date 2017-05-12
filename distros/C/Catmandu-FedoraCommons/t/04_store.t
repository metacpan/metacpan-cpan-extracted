use Test::More tests=>21;
use Data::Dumper;

BEGIN { use_ok( 'Catmandu::Store::FedoraCommons' ); }
require_ok('Catmandu::Store::FedoraCommons');

my $host = $ENV{FEDORA_HOST} || "";
my $port = $ENV{FEDORA_PORT} || "";
my $user = $ENV{FEDORA_USER} || "";
my $pwd  = $ENV{FEDORA_PWD}  || "";

SKIP: {
     skip "No Fedora server environment settings found (FEDORA_HOST,"
	 . "FEDORA_PORT,FEDORA_USER,FEDORA_PWD).", 
	 19 if (! $host || ! $port || ! $user || ! $pwd);

     ok($x = Catmandu::Store::FedoraCommons->new(baseurl => "http://$host:$port/fedora", username => $user, password => $pwd), "new");
     
     ok($x->fedora, 'fedora');
     
     my $count = 0;
     $x->bag('demo')->take(10)->each(sub { 
         my $obj = $_[0];
         $count++;
         ok($obj,"take(10) - $count");
     });
     
     ok($obj = $x->bag('demo')->add({ title => ['test']}), 'add');
     
     my $pid = $obj->{_id};
     
     ok($pid,"pid = $pid");
     
     is($obj->{title}->[0] , 'test' , 'obj content ok');
     
     $obj->{creator}->[0] = 'Patrick';
     
     ok($x->bag('demo')->add($obj),'update using add');
     
     ok($x->bag('demo')->get($pid), 'get');
     
     is($obj->{creator}->[0] , 'Patrick' , 'obj content ok');
     
     ok($x->bag('demo')->delete($pid), "delete $pid");
     
     #print Dumper($x->bag->delete_all());
}
