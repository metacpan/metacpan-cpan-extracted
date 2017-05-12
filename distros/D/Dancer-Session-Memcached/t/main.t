use strict;
use warnings;

use Test::More tests => 5;

use Dancer::Config 'setting';
use Dancer::Session::Memcached;

eval { Dancer::Session::Memcached->create };
like $@, qr/The setting memcached_servers must be defined/, 
    "setting memcached_servers is mandatory";

setting memcached_servers => '1.2.3.4';
eval { Dancer::Session::Memcached->create };
like $@, qr/server `1\.2\.3\.4' is invalid; port is missing, use `server:port'/, 
    "setting memcached_servers's syntax must be IP:PORT";

my $engine;
setting memcached_servers => '1.2.3.4:7777';
eval { $engine = Dancer::Session::Memcached->create };
is $@, '', 'engine created with a good setting';

isa_ok $engine, 'Dancer::Session::Memcached';
can_ok $engine, qw(create retrieve flush destroy init);

