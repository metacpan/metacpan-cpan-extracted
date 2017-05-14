use strict;
use AutoSQL::EasyArgv;

my $db =get_autosql_db_from_argv;


my ($dbname, $host, $user, $pass, $schema_file)=
    ($db->dbname, $db->host, $db->user, $db->pass);

# Check whether the database is exists.
`mysqladmin -h $host -u $user create $dbname`;

sleep(2);
use lib 't/lib/';
use ContactSchema;
my $schema=ContactSchema->new;
use AutoSQL::SQLGenerator;
my @sql=AutoSQL::SQLGenerator->generate_table_sql($schema);

foreach(@sql){
    print STDOUT "$_\n";
    my $sth=$db->prepare($_);
    $sth->execute or print STDERR $db->db_handle->errstr ."\n";
}

