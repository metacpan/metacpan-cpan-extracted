#! perl -w

use strict;
use warnings;
use Test::Most;
use App::JESP;

# Test deployment in SQLite
# use Log::Any::Adapter qw/Stderr/;

use File::Temp;
use File::Which;

if( $^O =~ /Win/ ){
    plan skip_all => 'No script test on windows please';
}

my $which_sqlite3 = File::Which::which('sqlite3');
unless( $which_sqlite3 ){
    plan skip_all => 'No sqlite3 found';
}
delete $ENV{PATH};
$ENV{WHICH_SQLITE3} = $which_sqlite3;

my ($fh, $dbname) = File::Temp::tempfile( EXLOCK => 0 );

# A home that is there.
my $jesp = App::JESP->new({ dsn => "dbi:SQLite:dbname=$dbname",
                            username => undef,
                            password => undef,
                            home => './t/homescripts/'
                        });

# Time to install
$jesp->install();
is( $jesp->deploy(), 3, "Ok applied 3 patches");

unlink $dbname;

done_testing();
