#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use t::lib::Test;
use Test::More;

BEGIN { requires_sqlite('3.7.7') }

plan tests => 17;
use DBI;
use DBD::SQLcipher;

my $dbfile = dbfile('foo');
my %uri = (
  base => "file:$dbfile",
  ro   => "file:$dbfile?mode=ro",
  rw   => "file:$dbfile?mode=rw",
  rwc  => "file:$dbfile?mode=rwc",
);

sub cleanup {
  unlink $dbfile if -f $dbfile;
  unlink "file" if -f "file"; # for Win32
  for (keys %uri) {
    unlink $uri{$_} if -f $uri{$_};
  }
}

cleanup();

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{base}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && $dbh && !-f $dbfile, "correct database is not created for uri";
  $dbh->disconnect;
  cleanup();
}

# uri=(uri)
{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:uri=$uri{base}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base}, "correct database is created for uri";
  $dbh->disconnect;
  cleanup();
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:uri=$uri{ro}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok $@ && !$dbh && !-f $dbfile && !-f $uri{base} && !-f $uri{ro}, "failed to open a nonexistent readonly database for uri";
  cleanup();
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:uri=$uri{rw}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok $@ && !$dbh && !-f $dbfile && !-f $uri{base} && !-f $uri{rw}, "failed to open a nonexistent readwrite database for uri";
  cleanup();
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:uri=$uri{rwc}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base} && !-f $uri{rwc}, "correct database is created for uri";
  $dbh->disconnect;
  cleanup();
}

{
  eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:uri=$uri{ro}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base} && !-f $uri{ro}, "opened a correct readonly database for uri";
  $dbh->disconnect;
  cleanup();
}

{
  eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:uri=$uri{rw}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base} && !-f $uri{rw}, "opened a correct readwrite database for uri";
  $dbh->disconnect;
  cleanup();
}

# OPEN_URI flag
{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{base}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base}, "correct database is created for uri";
  $dbh->disconnect;
  cleanup();
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{ro}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok $@ && !$dbh && !-f $dbfile && !-f $uri{base} && !-f $uri{ro}, "failed to open a nonexistent readonly database for uri";
  cleanup();
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{rw}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok $@ && !$dbh && !-f $dbfile && !-f $uri{base} && !-f $uri{rw}, "failed to open a nonexistent readwrite database for uri";
  cleanup();
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{rwc}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base} && !-f $uri{rwc}, "correct database is created for uri";
  $dbh->disconnect;
  cleanup();
}

{
  eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{ro}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base} && !-f $uri{ro}, "opened a correct readonly database for uri";
  $dbh->disconnect;
  cleanup();
}

{
  eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$uri{rw}", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok !$@ && $dbh && -f $dbfile && !-f $uri{base} && !-f $uri{rw}, "opened a correct readwrite database for uri";
  $dbh->disconnect;
  cleanup();
}
