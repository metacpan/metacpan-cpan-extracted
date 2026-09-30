#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use DBI;
use English qw(-no_match_vars);
use File::Copy qw(copy);
use File::Temp qw(tempfile);
use Test::More;

use_ok(qw(DarkPAN::Resolver::SQLite));

{
  package Local::DarkPAN::Resolver::SQLite;

  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use parent qw(DarkPAN::Resolver::SQLite);

  our $DATABASE;

  ########################################################################
  sub _fetch_packages_version_index {
  ########################################################################
    my ($self) = @_;

    my ( $fh, $database ) = File::Temp::tempfile(
      UNLINK => 0,
      SUFFIX => '.db',
      DIR    => '/tmp',
    );

    close $fh;

    File::Copy::copy( $DATABASE, $database )
      or die "ERROR: could not copy $DATABASE to $database: $OS_ERROR";

    return $database;
  }
}

my ( $seed_fh, $seed_database ) = tempfile(
  UNLINK => 0,
  SUFFIX => '.db',
  DIR    => '/tmp',
);

close $seed_fh;

my $dbh = DBI->connect(
  "dbi:SQLite:dbname=$seed_database",
  q{},
  q{},
  {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 1,
  },
);

$dbh->do(
  q{
    CREATE TABLE modules (
      distribution TEXT NOT NULL,
      module       TEXT NOT NULL,
      version      TEXT NOT NULL
    )
  }
);

$dbh->do(
  q{
    CREATE INDEX modules_module_idx
      ON modules(module)
  }
);

my $insert = $dbh->prepare(
  q{
    INSERT INTO modules (
      distribution,
      module,
      version
    )
    VALUES (?, ?, ?)
  }
);

for my $row (
  [
    'authors/id/A/AB/ABC/Foo-Bar-1.9.0.tar.gz',
    'Foo::Bar',
    'v1.9.0',
  ],
  [
    'orepan2/authors/id/A/AB/ABC/Foo-Bar-1.10.0.tar.gz',
    'Foo::Bar',
    'v1.10.0',
  ],
  [
    'authors/id/A/AB/ABC/Foo-Bar-2.0.0.tar.gz',
    'Foo::Bar',
    'v2.0.0',
  ],
  [
    'authors/id/X/XY/XYZ/Baz-Quux-3.2.1.tar.gz',
    'Baz::Quux',
    'v3.2.1',
  ],
) {
  $insert->execute( @{$row} );
}

$dbh->disconnect;

$Local::DarkPAN::Resolver::SQLite::DATABASE = $seed_database;

my $mirror = 'https://cpan.example.test/orepan2';

########################################################################
subtest 'highest version wins without a constraint' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Foo::Bar',
      version_range => undef,
    },
  );

  is_deeply(
    $result,
    {
      source   => 'cpan',
      distfile => 'A/AB/ABC/Foo-Bar-2.0.0.tar.gz',
      uri      => "$mirror/authors/id/A/AB/ABC/Foo-Bar-2.0.0.tar.gz",
      version  => 'v2.0.0',
      package  => 'Foo::Bar',
    },
    'selected highest available version',
  );
};

########################################################################
subtest 'version comparison is semantic rather than lexical' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Foo::Bar',
      version_range => '>= 1.0, < 2.0',
    },
  );

  is_deeply(
    $result,
    {
      source   => 'cpan',
      distfile => 'A/AB/ABC/Foo-Bar-1.10.0.tar.gz',
      uri      => "$mirror/authors/id/A/AB/ABC/Foo-Bar-1.10.0.tar.gz",
      version  => 'v1.10.0',
      package  => 'Foo::Bar',
    },
    'v1.10.0 sorts above v1.9.0',
  );
};

########################################################################
subtest 'exact version constraint selects requested version' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Foo::Bar',
      version_range => '== 1.9.0',
    },
  );

  is_deeply(
    $result,
    {
      source   => 'cpan',
      distfile => 'A/AB/ABC/Foo-Bar-1.9.0.tar.gz',
      uri      => "$mirror/authors/id/A/AB/ABC/Foo-Bar-1.9.0.tar.gz",
      version  => 'v1.9.0',
      package  => 'Foo::Bar',
    },
    'exact version selected',
  );
};

########################################################################
subtest 'prefixed distribution key is converted to CPAN path' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Foo::Bar',
      version_range => '== 1.10.0',
    },
  );

  is(
    $result->{distfile},
    'A/AB/ABC/Foo-Bar-1.10.0.tar.gz',
    'bucket prefix removed from distribution key',
  );

  is(
    $result->{uri},
    "$mirror/authors/id/A/AB/ABC/Foo-Bar-1.10.0.tar.gz",
    'CPAN URI constructed from prefixed distribution key',
  );
};

########################################################################
subtest 'missing package returns resolver error' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Does::Not::Exist',
      version_range => undef,
    },
  );

  like(
    $result->{error},
    qr/^not found in /,
    'missing package reported',
  );
};

########################################################################
subtest 'unsatisfied version range returns resolver error' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Foo::Bar',
      version_range => '>= 3.0',
    },
  );

  like(
    $result->{error},
    qr/^found version\(s\) for Foo::Bar, none satisfy >= 3\.0, /,
    'unsatisfied version range reported',
  );
};

########################################################################
subtest 'single-version package resolves normally' => sub {
########################################################################
  my $resolver = Local::DarkPAN::Resolver::SQLite->new(
    undef,
    $mirror,
  );

  my $result = $resolver->resolve(
    undef,
    {
      package       => 'Baz::Quux',
      version_range => undef,
    },
  );

  is_deeply(
    $result,
    {
      source   => 'cpan',
      distfile => 'X/XY/XYZ/Baz-Quux-3.2.1.tar.gz',
      uri      => "$mirror/authors/id/X/XY/XYZ/Baz-Quux-3.2.1.tar.gz",
      version  => 'v3.2.1',
      package  => 'Baz::Quux',
    },
    'single available version resolved',
  );
};

done_testing;

END {
  if ( $seed_database && -e $seed_database ) {
    unlink $seed_database;
  }
}

1;
