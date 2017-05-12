# $Id: basics.t,v 1.9 2009-02-10 15:08:12 cantrelld Exp $

use strict;
use warnings;

my $dbfile = require 't/sqlite_create_db.pl';
END { unlink $dbfile; }

use Test::More tests => 20;
use File::Temp;
use File::Spec;

use Class::DBI::ClassGenerator;

my $dsn = ["dbi:SQLite:dbname=$dbfile", '', ''];
my $db_driver = Class::DBI::ClassGenerator::_get_db_driver($dsn);
my $dbh       = Class::DBI::ClassGenerator::_get_dbh($dsn);

ok(-e $dbfile, "temp db file $dbfile exists");

my $dir = File::Temp->newdir();
ok(-d $dir, "temp dir $dir exists");

ok(Class::DBI::ClassGenerator::_mkdir($dir, 'Some::Random::Silly::Class')
   eq File::Spec->catdir($dir, 'Some', 'Random', 'Silly'),
   "_mkdir returns right value");
ok(-d File::Spec->catdir($dir, 'Some'), "$dir/Some exists");
ok(-d File::Spec->catdir($dir, 'Some', 'Random'),
    "$dir/Some/Random exists");
ok(-d File::Spec->catdir($dir, 'Some', 'Random', 'Silly'),
    "$dir/Some/Random/Silly exists");
ok(!-e File::Spec->catdir($dir, 'Some', 'Random', 'Silly', 'Class'),
    "$dir/Some/Random/Silly/Class doesn't exist");

is_deeply(
    [qw(address person)],
    [sort { $a cmp $b } $db_driver->_get_tables($dbh)],
    "Got list of tables from DB"
);
is_deeply(
    {$db_driver->_get_columns($dbh, 'person')},
    {
        id          => { type => '', pk => 1, null => !!0, default => 0     },
        known_as    => { type => '', pk => 0, null => !!1, default => undef },
        formal_name => { type => '', pk => 0, null => !!1, default => undef },
        dob         => { type => '', pk => 0, null => !!1, default => undef }
    },
    "Got list of columns from a table"
);

eval "Class::DBI::ClassGenerator::create(
    # directory    => '$dir',
    connect_info => [qw(a b c)],
    base_class   => 'A::Class'
)";
ok($@ =~ /no directory specified/, "must specify a directory");
eval "Class::DBI::ClassGenerator::create(
    directory    => '$dir',
    # connect_info => [qw(a b c)],
    base_class   => 'A::Class'
)";
ok($@ =~ /no connect_info specified/, "must specify connect_info");
eval "Class::DBI::ClassGenerator::create(
    directory    => '$dir',
    connect_info => [qw(a b c)],
    # base_class   => 'A::Class'
)";
ok($@ =~ /no base class specified/, "must specify a base class");
ok(!-d File::Spec->catdir($dir, 'A'), "and nothing was inadvertently created");

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
