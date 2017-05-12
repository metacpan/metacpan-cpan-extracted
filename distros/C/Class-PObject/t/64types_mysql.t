

# 64types_mysql.t,v 1.3 2003/09/09 08:46:38 sherzodr Exp

BEGIN {
    for ( "DBI", "DBD::mysql" ) {
        eval "require $_";
        if ( $@ ) {
            print "1..0 #Skipped: $_ is not available\n";
            exit(0)
        }
    }
    unless ( $ENV{MYSQL_DB} && $ENV{MYSQL_USER} ) {
        print "1..0 #Skipped: Read INSTALL for details on running mysql-related tests";
        exit(0)
    }
}

my %dsn = (
    DSN => "dbi:mysql:$ENV{MYSQL_DB}",
    User => $ENV{MYSQL_USER},
    Password => $ENV{MYSQL_PASSWORD}
);

use Class::PObject::Test::Types;
my $t = new Class::PObject::Test::Types('mysql', \%dsn );
$t->run();
