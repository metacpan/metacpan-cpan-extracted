package MyTest;

use strict;
use warnings;
use vars qw(@ISA @EXPORT);
use DBIx::JSON;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(check_mysql);

sub check_mysql {
    my $host       = 'localhost';
    my $port       = '3306';
    my $dsn        = "dbname=mysql;host=$host;port=$port";
    my $dbusername = '';
    my $dbpasswd   = '';
    eval {
        my $obj = DBIx::JSON->new( $dsn, "mysql", $dbusername, $dbpasswd );
        $obj->do_select("select * from user;")->get_json;
        $obj->do_select( "select * from user;", "User" )->get_json;
        $obj->do_select( "select * from user;", "User", 1 )->get_json;
    };
    return !$@;
}

sub check_pg {
    1;
}

sub check_csv {
    1;
}

