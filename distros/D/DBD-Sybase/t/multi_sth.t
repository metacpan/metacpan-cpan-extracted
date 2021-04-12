# -*-Perl-*-
# $Id: multi_sth.t,v 1.3 2005/10/01 13:05:13 mpeppler Exp $
#
#
# Multiple sth on single dbh test.

use lib 't';
use _test;
use strict;

use Test::More tests => 43;

#use Test::More qw(no_plan);

BEGIN {
  use_ok('DBI');
  use_ok('DBD::Sybase');
}

use vars qw($Pwd $Uid $Srv $Db);

( $Uid, $Pwd, $Srv, $Db ) = _test::get_info();

my $dbh = DBI->connect(
  "dbi:Sybase:$Srv;database=$Db",
  $Uid, $Pwd,
  {
    PrintError => 0,
    AutoCommit => 1,
  }
);

ok( defined($dbh), 'Connect' );
if ( !$dbh ) {
  warn
"No connection - did you set the user, password and server name correctly in PWD?\n";
  for ( 4 .. 43 ) {
    ok(0);
  }
  exit(0);
}

test1($dbh);
test2($dbh);
test3($dbh);
test4($dbh);
test5($dbh);
test6($dbh);

# Vanilla test - do the "correct" prepare/execute handling.
sub test1 {
  my $dbh = shift;

  my $rc;

  my $sth1 = $dbh->prepare("select * from master..sysprocesses");
  ok( defined($sth1), 'test1 prepare1' );
  my $sth2 = $dbh->prepare("select * from sysusers");
  ok( defined($sth2), 'test1 prepare2' );

  $rc = $sth1->execute;
  ok( defined($rc), 'test1 execute1' );
  $rc = 0;
  while ( my $d = $sth1->fetch ) {
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
  }
  if ( $sth1->err ) {
    $rc = $sth1->err;
  }
  ok( $rc == 0, "test1 fetch1" );
  $rc = $sth2->execute;
  ok( defined($rc), 'test1 execute2' );
  $rc = 0;
  while ( my $d = $sth2->fetch ) {
    if ( $sth2->err ) {
      $rc = $sth2->err;
    }
  }
  if ( $sth2->err ) {
    $rc = $sth2->err;
  }
  ok( $rc == 0, "test1 fetch2" );
}

# Same thing, with placeholders.
sub test2 {
  my $dbh = shift;

SKIP: {
    skip '? placeholders not supported', 6 unless $dbh->{syb_dynamic_supported};

    my $rc;

    my $sth1 =
      $dbh->prepare("select * from master..sysprocesses where spid = ?");
    ok( defined($sth1), 'test2 prepare1' );
    my $sth2 = $dbh->prepare("select * from sysusers where uid = ?");
    ok( defined($sth2), 'test2 prepare2' );

    $rc = $sth1->execute(1);
    ok( defined($rc), 'test2 execute1' );
    $rc = 0;
    while ( my $d = $sth1->fetch ) {
      if ( $sth1->err ) {
        $rc = $sth1->err;
      }
    }
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
    ok( $rc == 0, "test2 fetch1" );
    $rc = $sth2->execute(1);
    ok( defined($rc), 'test2 execute2' );
    $rc = 0;
    while ( my $d = $sth2->fetch ) {
      if ( $sth2->err ) {
        $rc = $sth2->err;
      }
    }
    if ( $sth2->err ) {
      $rc = $sth2->err;
    }
    ok( $rc == 0, "test2 fetch2" );
  }    # SKIP
}

# Same thing, with placeholders.
sub test3 {
  my $dbh = shift;

SKIP: {
    skip '? placeholders not supported', 6 unless $dbh->{syb_dynamic_supported};
    my $rc;

    my $sth1 =
      $dbh->prepare("select * from master..sysprocesses where spid = ?");
    ok( defined($sth1), 'test3 prepare1' );
    my $sth2 = $dbh->prepare("select * from sysusers where uid = ?");
    ok( defined($sth2), 'test3 prepare2' );

    $rc = $sth1->execute(1);
    ok( defined($rc), 'test3 execute1' );

    # Interleaved execute()

    $rc = $sth2->execute(1);
    ok( defined($rc), 'test3 execute2' );

    $rc = 0;
    while ( my $d = $sth1->fetch ) {
      if ( $sth1->err ) {
        $rc = $sth1->err;
      }
    }
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
    ok( $rc == 0, "test3 fetch1" );

    $rc = 0;

    #DBI->trace(4);
    while ( my $d = $sth2->fetch ) {
      if ( $sth2->err ) {
        $rc = $sth2->err;
      }
    }
    if ( $sth2->err ) {
      $rc = $sth2->err;
    }
    ok( $rc == 0, "test3 fetch2" );
  }    #SKIP
}

# Same thing, first with placeholders, second without
sub test4 {
  my $dbh = shift;

SKIP: {
    skip '? placeholders not supported', 6 unless $dbh->{syb_dynamic_supported};

    my $rc;

    my $sth1 =
      $dbh->prepare("select * from master..sysprocesses where spid = ?");
    ok( defined($sth1), 'test4 prepare1' );
    my $sth2 = $dbh->prepare("select * from sysusers");
    ok( defined($sth2), 'test4 prepare2' );

    $rc = $sth1->execute(1);
    ok( defined($rc), 'test4 execute1' );

    # Interleaved execute()
    $rc = $sth2->execute();
    ok( defined($rc), 'test4 execute2' );

    $rc = 0;
    while ( my $d = $sth1->fetch ) {
      if ( $sth1->err ) {
        $rc = $sth1->err;
      }
    }
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
    ok( $rc == 0, "test4 fetch1" );

    $rc = 0;

    #DBI->trace(4);
    while ( my $d = $sth2->fetch ) {
      if ( $sth2->err ) {
        $rc = $sth2->err;
      }
    }
    if ( $sth2->err ) {
      $rc = $sth2->err;
    }
    ok( $rc == 0, "test4 fetch2" );
  }    #SKIP
}

# This time, set the "no_child_con" flag, and execute the statements
# sequentially.
sub test5 {
  my $dbh = shift;

SKIP: {
    skip '? placeholders not supported', 8 unless $dbh->{syb_dynamic_supported};
    my $rc;

    $dbh->{syb_no_child_con} = 1;

    my $sth1 =
      $dbh->prepare("select * from master..sysprocesses where spid = ?");
    ok( defined($sth1), 'test5 prepare1' );

    $rc = $sth1->execute(1);
    ok( defined($rc), 'test5 execute1' );

    $rc = 0;
    while ( my $d = $sth1->fetch ) {
      if ( $sth1->err ) {
        $rc = $sth1->err;
      }
    }
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
    ok( $rc == 0, "test5 fetch1" );

    my $sth2 = $dbh->prepare("select * from sysusers");
    ok( defined($sth2), 'test5 prepare2' );
    $rc = $sth2->execute();
    ok( defined($rc), 'test5 execute2' );

    $rc = 0;

    #DBI->trace(4);
    while ( my $d = $sth2->fetch ) {
      if ( $sth2->err ) {
        $rc = $sth2->err;
      }
    }
    if ( $sth2->err ) {
      $rc = $sth2->err;
    }
    ok( $rc == 0, "test5 fetch2" );

    $rc = $sth1->execute(1);
    ok( defined($rc), 'test5 execute3' );

    $rc = 0;
    while ( my $d = $sth1->fetch ) {
      if ( $sth1->err ) {
        $rc = $sth1->err;
      }
    }
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
    ok( $rc == 0, "test5 fetch3" );
  }    #SKIP

  $dbh->{syb_no_child_con} = 0;

}

# This time, set the "no_child_con" flag, and execute the statements
# sequentially. Same as test5, but no dynamic SQL.
sub test6 {
  my $dbh = shift;

  my $rc;

  $dbh->{syb_no_child_con} = 1;

  my $sth1 = $dbh->prepare("select * from master..sysprocesses");
  ok( defined($sth1), 'test6 prepare1' );

  $rc = $sth1->execute();
  ok( defined($rc), 'test6 execute1' );

  $rc = 0;
  while ( my $d = $sth1->fetch ) {
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
  }
  if ( $sth1->err ) {
    $rc = $sth1->err;
  }
  ok( $rc == 0, "test6 fetch1" );

  my $sth2 = $dbh->prepare("select * from sysusers");
  ok( defined($sth2), 'test6 prepare2' );
  $rc = $sth2->execute();
  ok( defined($rc), 'test6 execute2' );

  $rc = 0;

  #DBI->trace(4);
  while ( my $d = $sth2->fetch ) {
    if ( $sth2->err ) {
      $rc = $sth2->err;
    }
  }
  if ( $sth2->err ) {
    $rc = $sth2->err;
  }
  ok( $rc == 0, "test6 fetch2" );

  $rc = $sth1->execute();
  ok( defined($rc), 'test6 execute3' );

  $rc = 0;
  while ( my $d = $sth1->fetch ) {
    if ( $sth1->err ) {
      $rc = $sth1->err;
    }
  }
  if ( $sth1->err ) {
    $rc = $sth1->err;
  }
  ok( $rc == 0, "test6 fetch3" );

  $dbh->{syb_no_child_con} = 0;

}
