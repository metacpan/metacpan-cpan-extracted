# $Id: mysql_create_db.pl,v 1.1 2008-08-27 15:09:31 cantrelld Exp $

use strict;
use warnings;

use DBI;

my $drh = DBI->install_driver("mysql");

my $dbname = 'DRCcdbicgentest01';
while(!$drh->func('createdb', $dbname, 'localhost', 'root', '', 'admin')) {
    $dbname++;
    last if($dbname eq 'DRCcdbicgentest10');
}
END {
    $drh->func('dropdb', $dbname, 'localhost', 'root', '', 'admin')
}

if($dbname ne 'DRCcdbicgentest10') {
    my $dbh = DBI->connect("dbi:mysql:database=$dbname", 'root', '');

    $dbh->do(q{
        CREATE TABLE person (
            id          INT PRIMARY KEY NOT NULL,
            known_as    VARCHAR(128),
            formal_name VARCHAR(128),
            dob         DATETIME
        );
    });
    $dbh->do(q{
        CREATE TABLE address (
            id          INT PRIMARY KEY,
            person_id   INT,
            address_text VARCHAR(255),
            postcode_area CHAR(4),
            postcode_street CHAR(3)
        );
    });
}
$dbname;
