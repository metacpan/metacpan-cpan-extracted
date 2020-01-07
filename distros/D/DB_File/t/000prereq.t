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

    use_ok('DB_File', '1.852');
}

if (defined $DB_File::VERSION)
{
    diag <<"EOM" ;


DB_File version            $DB_File::VERSION
DB_File::db_version        $DB_File::db_version
DB_File::db_ver            $DB_File::db_ver

EOM
}

