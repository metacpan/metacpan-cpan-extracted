# $Id: mysql.t,v 1.3 2008-08-28 17:11:22 cantrelld Exp $

use strict;
use warnings;

eval "use DBD::mysql";
my $dbname;
if($@) {
    eval 'use Test::More skip_all => "no DBD::mysql installed";exit 0';
} else {
    $dbname = require 't/mysql_create_db.pl';
    if($dbname eq 'DRCcdbicgentest10') {
         eval 'use Test::More skip_all => "couldn\'t create test db";exit 0';
    } else {
        eval 'use Test::More tests => 11';
    }
}

use File::Temp;
use File::Spec;

use Class::DBI::ClassGenerator;

my $dsn = ["dbi:mysql:database=$dbname", 'root', ''];
my $db_driver = Class::DBI::ClassGenerator::_get_db_driver($dsn);
my $dbh       = Class::DBI::ClassGenerator::_get_dbh($dsn);

ok($dbh, "using database $dbname");
my $dir = File::Temp->newdir();
ok(-d $dir, "temp dir $dir exists");

is_deeply(
    [qw(address person)],
    [sort { $a cmp $b } $db_driver->_get_tables($dbh)],
    "Got list of tables from DB"
);
is_deeply(
    do {
      my %r = $db_driver->_get_columns($dbh, 'person');
      $r{id}->{default} = ''; # some versions of the DB return undef here
      \%r;
    },
    {
        id          => { type => 'int(11)',      pk => 1,   null => !!0, default => '' },
        known_as    => { type => 'varchar(128)', pk => !!0, null => !!1, default => undef },
        formal_name => { type => 'varchar(128)', pk => !!0, null => !!1, default => undef },
        dob         => { type => 'datetime',     pk => !!0, null => !!1, default => undef }
    },
    "Got list of columns from a table"
);

is_deeply(
    [sort { $a cmp $b } Class::DBI::ClassGenerator::create(
        directory    => $dir,
        connect_info => $dsn,
        base_class   => 'A::Class'
    )],
    [
        File::Spec->catfile($dir, qw(A Class.pm)),
        File::Spec->catfile($dir, qw(A Class Address.pm)),
        File::Spec->catfile($dir, qw(A Class Person.pm))
    ],
    "right list of files is returned ..."
);
ok(-f $_, "... and $_ exists") foreach(
    File::Spec->catfile($dir, qw(A Class.pm)),
    File::Spec->catfile($dir, qw(A Class Address.pm)),
    File::Spec->catfile($dir, qw(A Class Person.pm))
);

is_deeply(
    [sort { $a cmp $b } Class::DBI::ClassGenerator::create(
        directory    => $dir,
        connect_info => $dsn,
        base_class   => 'Another::Class',
        tables       => { person => 'Another::Class::Table::Blah::Person' }
    )],
    [
        File::Spec->catfile($dir, qw(Another Class.pm)),
        File::Spec->catfile($dir, qw(Another Class Table Blah Person.pm))
    ],
    "right list of files is returned  when we only ask for particular tables ..."
);
ok(-f $_, "... and $_ exists") foreach(
    File::Spec->catfile($dir, qw(Another Class.pm)),
    File::Spec->catfile($dir, qw(Another Class Table Blah Person.pm))
);

# add tests here for the *contents* of those files
