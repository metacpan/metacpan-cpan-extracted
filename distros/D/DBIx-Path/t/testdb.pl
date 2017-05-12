package DBIxPathTest;

use strict;
use warnings;

use DBI;

my $dbh=DBI->connect(
	$ENV{TESTCONN} || 'dbi:AnyData:',
	$ENV{TESTUSER} || '',
    $ENV{TESTPASS} || '',
    {RaiseError=>1}
);

eval { $dbh->do("DROP TABLE dbix_path_test") };

while(<DATA>) {
	chomp;
	next if /^#/;
	next unless $_;
    $dbh->do($_);
}

$main::dbh=$dbh;

END {
    unless($ENV{TESTKEEP}) {
        eval { $dbh->do("DROP TABLE dbix_path_test") };
	}
}

1;

__DATA__
#The following creates:
#     NAME     ID
# (root)      (00)
#  +-usr       01
#  | +-bin     05
#  | | `-perl  07
#  | `-local   06
#  +-var       02
#  | `-log     08
#  +-tmp       03
#  `-home      04
#    `-brent   09
#The root is implied (i.e. there's no actual node 0).

CREATE TABLE dbix_path_test ( pid INTEGER, name VARCHAR(16), id INTEGER )
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (0, 'usr', 1)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (0, 'var', 2)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (0, 'tmp', 3)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (0, 'home', 4)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (1, 'bin', 5)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (1, 'local', 6)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (5, 'perl', 7)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (2, 'log', 8)
INSERT INTO dbix_path_test ( pid, name, id ) VALUES (4, 'brent', 9)
