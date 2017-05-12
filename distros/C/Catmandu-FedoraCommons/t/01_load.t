use Test::More tests=>3;
use Data::Dumper;

BEGIN { use_ok( 'Catmandu::FedoraCommons' ); }
require_ok('Catmandu::FedoraCommons');

my $host = $ENV{FEDORA_HOST} || "";
my $port = $ENV{FEDORA_PORT} || "";
my $user = $ENV{FEDORA_USER} || "";
my $pwd  = $ENV{FEDORA_PWD} || "";

SKIP: {
     skip "No Fedora server environment settings found (FEDORA_HOST,"
	 . "FEDORA_PORT,FEDORA_USER,FEDORA_PWD).", 
	 1 if (! $host || ! $port || ! $user || ! $pwd);

     ok(Catmandu::FedoraCommons->new("http://$host:$port/fedora",$user,$pwd), "new");
}
