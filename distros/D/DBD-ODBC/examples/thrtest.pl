
# $Id$

use 5.008 ;
use threads ;
use threads::shared ;

use strict ;
use vars qw{$id $mode $login $userID $authHandler $passwd $authMode $data $dsn} ;

our $dsn : shared = $ENV{DBIDSN} || 'dbi:Oracle:host=wingr1;sid=ora81' || 'dbi:ODBC:test' ;
our $orashr : shared = '' ;

use DBI ;
use Carp ;
use Carp::Heavy ;

sub dotests
    {
    my ($doerr, $count) = @_ ;

    my $dbh = undef ;
    my $cursor1 = undef ;
    my $cursor2 = undef ;
    my $cursor3 = undef ;
    my $action ;
    my $tid = threads -> tid() ;
    my $concnt = 0 ;
    my $discnt = 0 ;
    my $half   = $count / 2 ;
    print "start tid = $tid\n" ;

    #DBI -> trace (3) ;

    $login = '' ;
    $authHandler = '' ;

    while (!defined($count) || $count--)
        {
        if (!$dbh)
            {
            print "connect #$concnt tid = $tid\n" ;
            $dbh = DBI -> connect ($dsn, 'scott', 'tiger', {'PrintError' => 1, ora_init_mode => 3, ora_dbh_share => \$orashr}) or die "Cannot connect to $ENV{DBIDSN}" ;
            $concnt++ ;
            #print "create from tid = $tid\n" ;
            #my $t = threads->create('dotests', $doerr, $count) ;
            #print "created ", $t -> tid, " from tid = $tid\n" ;
            }

        my $action = int(rand() * 10) ;
        print "--> #$tid action = $action  count = $count  doerr = $doerr\n" ;

        if ($action == 0 && $doerr )
            {
            # create a syntax error
            my $sth = $dbh->prepare("SELECT userID, authHandler FROM") ;
            die "no error" if (!$DBI::errstr) ;
            }
        elsif ($action == 1 && !$cursor1)
            {
            $cursor1 -> finish if ($cursor1) ;
            $cursor1 = $dbh->prepare("SELECT userID, authHandler, password
								 FROM thrtest1 WHERE login = ? and locked IS NULL
							 	 ORDER BY password");
            die "db error $DBI::errstr" if (!$doerr && $DBI::errstr) ;
            }
        elsif ($action == 2 && !$cursor2)
            {
            $cursor2 -> finish if ($cursor2) ;
	    $cursor2 = $dbh->prepare("SELECT authMode, data FROM
							 thrtest2 WHERE handlerID = ?");
            die "db error $DBI::errstr" if (!$doerr && $DBI::errstr) ;
	    }
        elsif ($action == 3 && !$cursor3)
            {
            $cursor3 -> finish if ($cursor3) ;
	    $cursor3 = $dbh->prepare("UPDATE thrtest2 SET lastLogin =
								 now() WHERE userID = ?");
            die "db error $DBI::errstr" if (!$doerr && $DBI::errstr) ;
	    }
        elsif ($action == 4 && $cursor1 && $login)
            {
            #$cursor1 -> finish if ($cursor1) ;
            #$cursor1 = $dbh->prepare("SELECT userID, authHandler, password
	    #							 FROM thrtest1 WHERE login = ? and locked IS NULL
	    #						 	 ORDER BY password");
            #
	    $cursor1->execute($login) ;
	    $cursor1->bind_columns(\($userID, $authHandler, $passwd));
	    $cursor1->fetch;
            die "**** user is = $userID, should = $id" if ($id ne $userID) ;
            die "**** db error $DBI::errstr" if (!$doerr && $DBI::errstr) ;
	        }
        elsif ($action == 5 && $authHandler && $cursor2)
            {
            #    $cursor2 -> finish if ($cursor2) ;
	    #    $cursor2 = $dbh->prepare("SELECT authMode, data FROM
	    #							 thrtest2 WHERE handlerID = ?");

	    $cursor2->execute($authHandler) ;
	    $cursor2->bind_columns(\($authMode, $data));
	    $cursor2->fetch;
            die "**** mode is = $authMode, should = $mode for $authHandler (login=$login)" if ($mode ne $authMode) ;
            die "**** db error $DBI::errstr" if (!$doerr && $DBI::errstr) ;
            }
        elsif ($action == 6)
            {
	        $cursor3 = undef ;
	        }
        elsif ($action == 7)
            {
	        $cursor2 = undef ;
	        }
        elsif ($action == 8)
            {
	        $cursor1 = undef ;
	        }
        elsif ($action == 9)
            {
	    $cursor3 = undef ;
	    $cursor2 = undef ;
	    $cursor1 = undef ;
	    if ($discnt++ % 10 == 0)
                {
                $dbh ->disconnect ;
                die "db error $DBI::errstr" if (!$doerr && $DBI::errstr) ;
                $dbh = undef ;
                }
	    my $i = int(rand() * 3) ;
            $login = ('richter', 'test', 'XX')[$i] ;
            $id    = ('gr', 'tt', 'xx')[$i] ;
            $mode  = ('Windows', 'Windows', '')[$i] ;
            $authHandler = '' ;

            print "test login = $login, id = $id, mode = $mode\n" ;

            if ($count < $half)
                {
                threads->create('dotests', $doerr, $count) ;
                $half = 0 ;
                }

            }
        threads -> yield () ;
        my @num = threads->list() ;
        print "#" . scalar(@num) . "\n" ;
        }
    threads->create('dotests', $doerr, $count) ;


    }

#-------------------------------------------------------------
#
# create table thrtest1 & thrtest2 and put some test data in
#

my $dbh = DBI -> connect ($ENV{DBIDSN}, 'scott', 'tiger') or die "Cannot connect to $ENV{DBIDSN}" ;
eval {
$dbh -> do ('drop table thrtest1') ;
$dbh -> do ('drop table thrtest2') ;
} ;

my $c = q{ create table thrtest1 (userID varchar(80), authHandler varchar(80), password varchar(80), login varchar(80), lastLogin date, locked int) } ;

$dbh -> do ($c) ;

my $c = q{ create table thrtest2 (handlerID varchar(80), authMode varchar(80), data varchar(80)) } ;

$dbh -> do ($c) ;


$dbh -> do ("insert into thrtest1 values ('gr', 'w32', '', 'richter', NULL, NULL)") ;
$dbh -> do ("insert into thrtest1 values ('tt', 'w32', '', 'test', NULL, NULL)") ;
$dbh -> do ("insert into thrtest1 values ('xx', '', 'xx', 'XX', NULL, NULL)") ;
$dbh -> do ("insert into thrtest2 values ('w32', 'Windows', 'mond:mond:ecos')") ;

#$dbh -> disconnect ;

threads->create('dotests', 1, 20) ;
threads->create('dotests', 1, 20) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 1) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0) ;
threads->create('dotests', 0, 20) ;
threads->create('dotests', 0, 20) ; #-> join;
#threads->create('dotests', 0) ; 
#threads->create('dotests', 0) ; 

dotests () ;




