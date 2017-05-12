#!perl

package Test::MigrationTest;

use strict;
use warnings;
use base q(Exporter);

our %test_opts;
do '_build/test_opts.ph'
    or die "failed to read test_opts.ph!";

our @drivers = qw(Pg mysql SQLite2);

our @EXPORT = qw(%test_opts dsn @drivers);

return 1;

sub dsn {
    my $driver = shift;
    
    if($driver eq 'SQLite2') {
        my $dsn = 'dbi:SQLite2:test_db';
    } elsif($driver eq 'Pg') {
        my $dsn = "dbi:$driver:dbname=" . $test_opts{"$driver\_db"};

        if($test_opts{"$driver\_host"}) {
            $dsn.=";host=" . $test_opts{"$driver\_host"};
        }
    
        if($test_opts{"$driver\_port"}) {
            $dsn.=";port=" . $test_opts{"$driver\_port"};
        }
        
        return $dsn;
    } elsif($driver eq 'mysql') {
        my $dsn = "dbi:$driver:database=" . $test_opts{"$driver\_db"};

        if($test_opts{"$driver\_host"}) {
            $dsn.=";host=" . $test_opts{"$driver\_host"};
        }
    
        if($test_opts{"$driver\_port"}) {
            $dsn.=";port=" . $test_opts{"$driver\_port"};
        }
        
        return $dsn;
    } else {
        die "unknown driver $driver";
    }
}
