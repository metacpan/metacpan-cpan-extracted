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
use util ;

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 1 + $extra ;

    use_ok('BerkeleyDB', '0.64');
}

if (defined $BerkeleyDB::VERSION)
{
    my $ver = BerkeleyDB::DB_VERSION_STRING();
    my $has_heap = 'Not Available' ;
    if ($BerkeleyDB::db_version >= 5.1)
    {
        $has_heap = BerkeleyDB::has_heap() ? 'True' : 'False';
    }

    # Is encryption support available?
    my $has_encryption = 'Not Available';

    if ($BerkeleyDB::db_version >= 4.1)
    {
        my $env = new BerkeleyDB::Env @StdErrFile,
                                    -Encrypt => {Password => "abc",
                                                Flags    => DB_ENCRYPT_AES
                                                };

        $has_encryption = 'True';
        $has_encryption = 'False'
            if $BerkeleyDB::Error =~ /Operation not supported/;
    }

    diag <<EOM ;


BerkeleyDB version            $BerkeleyDB::VERSION
BerkeleyDB::DB_VERSION_STRING $ver
BerkeleyDB::db_version        $BerkeleyDB::db_version
BerkeleyDB::db_ver            $BerkeleyDB::db_ver

Heap Support                  $has_heap
Encryption Support            $has_encryption

EOM
}