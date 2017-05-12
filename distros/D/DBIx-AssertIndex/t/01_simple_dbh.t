use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use t::Util;

use DBI;
use DBIx::AssertIndex;

my($mysqld, $dbh) = t::Util::setup_mysqld;

foreach my $method (qw/do
                       selectall_arrayref
                       selectcol_arrayref selectcol_arrayref
                       selectrow_array selectrow_arrayref selectrow_hashref
                      /,
                     [ 'selectall_hashref', 'Password' ],
                ){
    my @rest = ();
    if(ref($method) eq 'ARRAY'){
        ($method, @rest) = @$method;
    }
    my $res = t::Util::capture {
        $dbh->$method('SELECT * FROM user', @rest);
    };
    like($res, qr/explain alert/, $method);
}
done_testing;
