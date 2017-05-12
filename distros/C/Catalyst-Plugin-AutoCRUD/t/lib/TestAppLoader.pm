package TestAppLoader;

use strict;
use warnings;

use DBI;
use File::Temp;
use Class::Data::Inheritable;

__PACKAGE__->mk_classdata('__dbfile');

use Catalyst qw(AutoCRUD);

my $dbfile = File::Temp->new( UNLINK => 1, EXLOCK => 0);
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",'','');
open my $sql_fh, 't/lib/test_app.sql' or die "Can't read SQL file: $!";
{
    local $/ = '';  # empty line(s) are delimeters
    while (<$sql_fh>) {
        $dbh->do($_);
    }
}
close $sql_fh;
$dbh->disconnect;

# need to stash the filename so File::Temp doesn't clean it immediately
__PACKAGE__->__dbfile($dbfile);

__PACKAGE__->config(
    'Plugin::AutoCRUD' => {
        extjs2 => '/javascript/extjs-2',
        basepath => '',
    },
    'Model::AutoCRUD::DBIC' => {
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''],
    },
);
   
__PACKAGE__->setup;
1;
