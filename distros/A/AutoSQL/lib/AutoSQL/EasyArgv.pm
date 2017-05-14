package AutoSQL::EasyArgv;
use strict;
use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(get_autosql_db_from_argv);
use AutoSQL::DBSQL::DBContext;
use Getopt::Long;

sub get_autosql_db_from_argv {
    my ($db_file, $host, $user, $pass, $dbname, $driver)=
        (undef, 'localhost', 'root', undef, undef, 'mysql');
    Getopt::Long::config('pass_through');
    &GetOptions(
        'db_file=s' => \$db_file,
        'host|dbhost=s' => \$host,
        'user|dbuser=s' => \$user,
        'pass|dbpass=s' => \$pass,
        'driver|dbdriver=s' => \$driver,
        'dbname=s' => \$dbname
    );
    my $db;
    if(defined $db_file){
        -e $db_file or die "$db_file is defined but does not exist\n";
        eval{$db=do($db_file)};
        $@ and die"$db_file is not a perlobj file\n";
    }elsif(defined $host and defined $user and defined $dbname){
        $db = AutoSQL::DBSQL::DBContext->new(
            -host => $host,
            -user => $user,
            -pass => $pass,
            -driver => $driver,
            -dbname => $dbname
        );
    }else{
        die "Cannot get the db, due to the insufficient information\n";
    }
    return $db;
}
1;

