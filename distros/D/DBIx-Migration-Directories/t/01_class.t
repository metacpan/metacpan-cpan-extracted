#!perl

use strict;
use warnings;
use Test::More qw(no_plan);
use lib 't/tlib';

use Test::DummyDBI;

use_ok('DBIx::Migration::Directories');

my $mh;
my $dbh = Test::DummyDBI->new;

ok(
    $mh = DBIx::Migration::Directories->new(
        dbh     => $dbh,
        schema  => 'TestSchema',
        base    => 't/tetc',
    ),
    'Create an object'
);

is($mh->db->driver, 'dummy', 'auto-vivify driver name');
ok($mh->{base}, 'auto-vivify base directory');
is($mh->desired_version, 4, 'auto-vivify desired_version');

eval { $mh = DBIx::Migration::Directories->new(dbh => $dbh); };

like($@, qr/requires "schema" parameter/, '"schema" parameter required');

eval { $mh = DBIx::Migration::Directories->new(schema => 'TestSchema'); };

like($@, qr/requires "dbh" parameter/, '"dbh" parameter required');

eval {
    $mh = DBIx::Migration::Directories->new(
        dbh     => $dbh,
        base    => 't/tetc',
        schema  => 'TestSchema2'
    );
};

like(
    $@, qr{t/tetc/TestSchema2/dummy is not a directory},
    '"dir" correctly calculated'
);

eval {
    $mh = DBIx::Migration::Directories->new(
        dbh                     => $dbh,
        base                    => 't/tetc',
        schema                  => 'TestSchema',
        dir                     => 't/tetc/TestSchema',
        desired_version_from    => 'Test::DummyDBI',
    );
};

like(
    $@,
    qr{package "Test::DummyDBI" did not define \$VERSION},
    "desired_version_from - Package with no version"
);

eval {
    $mh = DBIx::Migration::Directories->new(
        dbh                     => $dbh,
        base                    => 't/tetc',
        schema                  => 'TestSchema',
        dir                     => 't/tetc/TestSchema',
        desired_version_from    => 'Test::DummyDBI::NoSuchPackage',
    );
};

like(
    $@,
    qr{require Test::DummyDBI::NoSuchPackage failed},
    "desired_version_from - Bogus package"
);

diag("Schema version is $DBIx::Migration::Directories::SCHEMA_VERSION");

$mh = DBIx::Migration::Directories->new(
    dbh                     => $dbh,
    base                    => 't/tetc',
    schema                  => 'TestSchema',
    dir                     => 't/tetc/TestSchema',
    desired_version_from    => 'DBIx::Migration::Directories',
);

is(
    $mh->desired_version, $DBIx::Migration::Directories::SCHEMA_VERSION, 
    'desired_version_from - Good package'
);

ok(
    $mh = $mh->new(
        dbh         =>  $dbh,
        base        =>  't/tetc',
        schema      =>  'OtherTest',
        dir         =>  't/tetc/TestSchema/_generic',
    ),
    'Initialize new object off of existing object'
);
    
is($mh->desired_version, 4, 'new object initializes properly');

ok(
    $mh = $mh->new(
        dbh                     =>      $dbh,
        dir                     =>      't/tetc/TestSchema',
        desired_version_from    =>      'TestSchema',
    ),
    'Initialize new object with desired_version_from'
);

is($mh->{schema}, 'TestSchema', 'schema name set from desired_version_from');
is($mh->desired_version, $TestSchema::VERSION, 'version number matches');

$mh = $mh->new(
    dbh                     =>      $dbh,
    base                    =>      't/tetc',
    schema                  =>      'TestSchema',
    current_version         =>      3,
);

is($mh->desired_version, 3, 'desired_version - Impossible to upgrade');

eval {
    $mh = $mh->new(
        dbh                     =>      $dbh,
        dir                     =>      't/tetc/TestSchema',
        schema                  =>      'TestSchema',
        current_version         =>      -1,
    );
};

like($@,
    qr/Failed to detect the highest version/,
    'Initialize new object with bad current_version'
);

SKIP: {
  mkdir('bogus-dir', 0000) or die $!;

  if(opendir(my $dir, 'bogus-dir')) {
    closedir $dir;
    chmod(0700, 'bogus-dir');
    rmdir('bogus-dir');

    skip "root can write to everything", 1;
  }

  eval {
      $mh = $mh->new(
          dbh                     =>      $dbh,
          dir                     =>      'bogus-dir',
          schema                  =>      'TestSchema',
          current_version         =>      -1,
      );
  };

  like($@,
      qr/^opendir\("bogus-dir"\) failed:/,
      'Initialize with directory we dont have access to'
  );

  chmod(0700, 'bogus-dir');
  rmdir('bogus-dir');
}

