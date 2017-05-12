#! perl -w

use Test::Most;
BEGIN{
    eval "use Test::mysqld";
    plan skip_all => "Test::mysqld is required for this test" if $@;
}

use App::JESP;
use File::Spec;

# use Log::Any::Adapter qw/Stderr/;

my $mysql =  eval{ Test::mysqld->new( my_cnf => {
    'skip-networking' => '1',
    socket => File::Spec->catfile( File::Spec->tmpdir() , 'socket-'.$$.'-testmysqld')
}) } or plan skip_all => $Test::mysqld::errstr;

my $dbh = DBI->connect( $mysql->dsn() , '', '' , { RaiseError => 1, AutoCommit => 1 });
$dbh->do('CREATE DATABASE grotest');
$dbh->do('GRANT ALL ON grotest.* TO \'salengro\'@\'localhost\' IDENTIFIED BY \'mufflin!\'');

my $dsn = $mysql->dsn();
$dsn =~ s/dbname=test/dbname=grotest/;
$dsn =~ s/;user=root//;

# # A home that is there.
my $jesp = App::JESP->new({ dsn => $dsn,
                            password => 'mufflin!',
                            username => 'salengro',
                            home => './t/home_mysql/'
                        });
$jesp->install();
# And deploy
is( $jesp->deploy(), 2, "Ok applied 2 patches");
is( $jesp->deploy(), 0, "Ok applied 0 patches on the second call");

done_testing();
