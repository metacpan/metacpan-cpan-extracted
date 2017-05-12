use strict;
use Test;
BEGIN { plan test => 3 }
END { ok(0) unless $::loaded }

# try to load the module
use Config::Natural;
$::loaded = 1;
ok(1);  #01

# check if the version is defined
ok( defined $Config::Natural::VERSION );  #02
ok( $Config::Natural::VERSION, '/^\d+\.\d+(?:_\d{2}|b\d*)?$/' );  #03
