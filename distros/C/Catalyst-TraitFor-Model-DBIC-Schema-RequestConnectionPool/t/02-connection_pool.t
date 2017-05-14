use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Catalyst::Test 'WookieServe';
use DBI;
use HTTP::Request::Common qw/GET/;
use Test::More tests => 2;

make_db({db_name => 'hairy', wookie => 'dirty harry'});
make_db({db_name => 'scary', wookie => 'alice'});

is(get(GET '/hairy_wookies') => 'dirty harry',  'Found the right hairy wookie');
is(get(GET '/scary_wookies') => 'alice',        'Found the right hairy wookie');

unlink $_ for map "$Bin/lib/WookieServe/$_.db", qw/hairy scary/;

sub make_db {
    my ($args) = @_;

    my $db  = "$Bin/lib/WookieServe/$args->{db_name}.db";
    unlink $db if -f $db;;

    my $dbh = DBI->connect("dbi:SQLite:$db", '', '', {
        RaiseError => 1,
        PrintError => 1,
        });

    $dbh->do(<<_EOF);
CREATE TABLE wookies (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(64)
    );
_EOF

    $dbh->do("INSERT INTO wookies (name) VALUES ('$args->{wookie}');");

    $dbh->disconnect;
    }
