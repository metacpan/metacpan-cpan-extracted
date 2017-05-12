use strict;
use Test;
BEGIN { plan test => 3 }
END { ok(0) unless $::loaded }

# try to load the module
use Acme::JavaTrace;
$::loaded = 1;
ok(1);  #01

# check if the version is defined
ok( defined $Acme::JavaTrace::VERSION );  #02
ok( $Acme::JavaTrace::VERSION, '/^\d+\.\d+(?:_\d{2}|b\d*)?$/' );  #03
