package TestTable;

use base 'Class::DBI';
use strict;

use File::Temp qw/tempfile/;
my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

__PACKAGE__->connection(@DSN);
__PACKAGE__->constructer;


__PACKAGE__->table('TestTable');
__PACKAGE__->columns('Primary', 'id');
__PACKAGE__->columns('Essential', qw(ess1 ess2 ess3));
__PACKAGE__->columns('Other', qw(oth1 oth2 oth3));


sub constructer {
    my $class = shift;
    $class->db_Main->do(<<SQL);
CREATE TABLE testtable (
    id   VARCHAR(10),
    ess1 VARCHAR(10),
    ess2 VARCHAR(10),
    ess3 VARCHAR(10),
    oth1 VARCHAR(10),
    oth2 VARCHAR(10),
    oth3 VARCHAR(10)
)
SQL

    foreach my $i (1..3) {
	$class->db_Main->do(<<SQL);
INSERT INTO TestTable 
(id, ess1, ess2, ess3, oth1, oth2, oth3)
VALUES
('id$i', 'ess1$i', 'ess2$i', 'ess3$i', 'oth1$i', 'oth2$i', 'oth3$i')
SQL
    }

    return 1;
}

1;
__END__
