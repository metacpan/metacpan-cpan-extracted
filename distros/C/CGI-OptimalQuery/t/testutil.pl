#!/usr/bin/perl

use strict;
use CGI::OptimalQuery();
use DBI();

package OQ;

our $DBTYPE;
our $DBH;
our $BUF;

sub dbhdo {
  my ($sql0, @rest) = @_;
  my $sql = $sql0;
  if ($DBTYPE =~ /ORACLE/) {

    if ($sql =~ /^CREATE/) {
      $sql =~ s/\bTEXT\b/CLOB/;
    }

  } elsif ($DBTYPE =~ /PG/) {
  } elsif ($DBTYPE =~ /SQLITE/) {
  } elsif ($DBTYPE =~ /MYSQL/) {
  } elsif ($DBTYPE =~ /SQLSERVER/) {
  }
  eval {
    $DBH->do($sql, @rest);
  }; if ($@) {
    my $err = $@;
    print STDERR "Error in SQL: $err\n$sql\n";
    print STDERR "Original untranslated SQL:\n$sql0\n" if $sql0 ne $sql;
    die $err;
  }
}

sub schema {
  my %schema = @_;
  if ($DBTYPE =~ /ORACLE/) {
  } elsif ($DBTYPE =~ /PG/) {
  } elsif ($DBTYPE =~ /SQLITE/) {
  } elsif ($DBTYPE =~ /MYSQL/) {
  } elsif ($DBTYPE =~ /SQLSERVER/) {
  }
  $schema{URI} = '/Movies';
  $schema{dbh} = $DBH;
  $schema{output_handler} = sub { $BUF .= $_[0]; },
  return CGI::OptimalQuery->new(\%schema);
}

sub _install {
  _cleanup();
  if ($DBTYPE =~ /ORACLE/) {
    $DBH->do("ALTER SESSION SET nls_date_format='yyyy-mm-dd'");
  } elsif ($DBTYPE =~ /PG/) {
  } elsif ($DBTYPE =~ /SQLITE/) {
  } elsif ($DBTYPE =~ /MYSQL/) {
  } elsif ($DBTYPE =~ /SQLSERVER/) {
  }

  dbhdo("CREATE TABLE oqtest_person (person_id INTEGER, name VARCHAR(1000), birthdate DATE)");
  dbhdo("INSERT INTO oqtest_person (person_id, name, birthdate) VALUES (1, 'Harrison Ford', '1942-07-13')");
  dbhdo("INSERT INTO oqtest_person (person_id, name, birthdate) VALUES (2, 'Mark Hamill', '1951-09-25')");
  dbhdo("INSERT INTO oqtest_person (person_id, name, birthdate) VALUES (3, 'Irvin Kershner', '1923-04-29')");
  dbhdo("INSERT INTO oqtest_person (person_id, name, birthdate) VALUES (4, 'Richard Marquand', '1938-01-01')");
  dbhdo("INSERT INTO oqtest_person (person_id, name, birthdate) VALUES (5, 'Steven Spielberg', '1946-12-18')");
  dbhdo("CREATE TABLE oqtest_movie (movie_id INTEGER, name VARCHAR(1000), releaseyear INTEGER, director_person_id INTEGER )");
  dbhdo("INSERT INTO oqtest_movie (movie_id,name,releaseyear,director_person_id) VALUES (1, 'The Empire Strikes Back', 1980, 3)");
  dbhdo("INSERT INTO oqtest_movie (movie_id,name,releaseyear,director_person_id) VALUES (2, 'Return of the Jedi', 1983, 4)");
  dbhdo("INSERT INTO oqtest_movie (movie_id,name,releaseyear,director_person_id) VALUES (3, 'Raiders of the Lost Ark', 1981, 5)");
  dbhdo("CREATE TABLE oqtest_moviecast (movie_id INTEGER, person_id INTEGER)");
  dbhdo("INSERT INTO oqtest_moviecast (movie_id,person_id) VALUES (1,1)");
  dbhdo("INSERT INTO oqtest_moviecast (movie_id,person_id) VALUES (1,2)");
  dbhdo("INSERT INTO oqtest_moviecast (movie_id,person_id) VALUES (2,1)");
  dbhdo("INSERT INTO oqtest_moviecast (movie_id,person_id) VALUES (2,2)");
  dbhdo("INSERT INTO oqtest_moviecast (movie_id,person_id) VALUES (3,1)");
}

sub _cleanup {
  local $$DBH{RaiseError} = 0;
  local $$DBH{PrintError} = 0;
  dbhdo("DROP TABLE oqtest_moviecast");
  dbhdo("DROP TABLE oqtest_movie");
  dbhdo("DROP TABLE oqtest_person");
}

sub foreachdb {
  my ($codeRef) = @_;

  while (my ($k,$v) = each %ENV) {
    if ($k =~ /^OQ_DSN_(.+)$/) {
      local $DBTYPE = $1;
      local $DBH;
      local $BUF = '';
      eval {
        $DBH = DBI->connect($ENV{"OQ_DSN_$DBTYPE"}, $ENV{"OQ_USER_$DBTYPE"}, $ENV{"OQ_PASS_$DBTYPE"}, { RaiseError => 1, PrintError => 1 }) or die $DBI::errstr;
        _install();
        $codeRef->();
      };
      if ($@) {
        print STDERR "Error DBTYPE:$DBTYPE; $@\n";
      }

      if ($DBH) {
        eval { _cleanup(); }; if($@){}
        eval { $DBH->disconnect(); }; if($@){}
      }
    }
  }
}

1;
