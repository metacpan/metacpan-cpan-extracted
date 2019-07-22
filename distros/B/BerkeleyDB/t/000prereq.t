BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict ;
use warnings ;

use Test::More ;

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 1 + $extra ;

    use_ok('BerkeleyDB', '0.63');
}

if (defined $BerkeleyDB::VERSION)
{
    my $ver = BerkeleyDB::DB_VERSION_STRING();

    diag <<EOM ;


BerkeleyDB version            $BerkeleyDB::VERSION
BerkeleyDB::DB_VERSION_STRING $ver
BerkeleyDB::db_version        $BerkeleyDB::db_version
BerkeleyDB::db_ver            $BerkeleyDB::db_ver

EOM
}