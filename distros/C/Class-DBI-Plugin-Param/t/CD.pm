package Music::CD;
use base 'Class::DBI';
use Class::DBI::Plugin::Param;
use File::Temp qw/tempfile/;

my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('cd');
__PACKAGE__->columns(All => qw/cdid artist title year reldate/);
__PACKAGE__->columns(TEMP => qw/date/);

sub CONSTRUCT {
    my $class = shift;
    $class->db_Main->do(qq{
        CREATE TABLE cd (
            cdid int UNSIGNED auto_increment,
            artist varchar(255),
            title varchar(255),
            year int,
            reldate date,
            PRIMARY KEY(cdid)
        )
    });
    $class->create({
        cdid    => '1',
        artist  => 'foo',
        title   => 'bar',
        year    => '2006',
        reldate => '2006-01-01',
    });
}

1;

