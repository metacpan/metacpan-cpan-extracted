
use Apache::SessionX ;
use Apache::SessionX::Config ;
use Apache::SessionX::Manager ;

use Config ;


BEGIN { eval "use Time::HiRes qw(gettimeofday tv_interval) ;" ; }
use strict ;

use vars qw(@tests %stdargs $timeout $errors $numprocs $win32) ;

$win32 = ($Config{osname} =~ /win32/i) ;

if (@ARGV)
    {
    @tests = @ARGV ;
    }
else
    {
    @tests = @Apache::SessionX::Config::confs ;
    }

%stdargs = (
    SemaphoreKey => 0x7654,
    ) ;

$timeout = defined (&DB::DB)?0:5 ;
$numprocs = 5 ;
$errors  = 0 ;

sub Check

    {
    my ($sess, $key, $val) = @_ ;

    if ($sess -> {$key} eq $val)
        {
        #print "ok\n" ;
        }
    else
        {
        print "\n\tERROR: $key should be $val but is $sess->{$key}\n" ;
        $errors++ ;
        }
    }

sub Error

    {
    my ($msg) = @_ ;

    print "ERROR: $msg\n" ;
    #push @errors, $msg ;

    $errors++ ;
    }

sub dosimpletest

    {
    my ($num, $msg, $cfg, $args, $args2, $id) = @_ ;

    my $sid ;
    my $init ;
    my $mod ;

    printf ('#%02d %-30s', $num, "$msg...") ;
        {
        my %sess ;
        my $obj = tie (%sess, 'Apache::SessionX', undef, { %stdargs, 'config' => $cfg, %$args})  or Error ("Cannot tie to Apache::SessionX") ;
        
        if ($args -> {lazy} && $obj -> getid)
            {
            Error ("is not lazy, id is not undef before access") ;
            return ;
            }
        elsif (!$args -> {lazy} && !$obj -> getid)
            {
            Error ("id is missing") ;
            return ;
            }
            


        $sess{'A' . $num} = 1 + $num * 2;
        $sess{'B' . $num} = 2 + $num * 2;

        ($init, $sid, $mod) = $obj -> getids ;

        if (($args -> {newid} || $args -> {recreate_id}) && $id && $id eq $sid)
            {
            Error ("id should have changed, but didn't (id=$id, session id=$sid") ;
            return ;
            }
        elsif (!($args -> {newid} || $args -> {recreate_id}) && $id && $id ne $sid)
            {
            Error ("id has changed, but should be the same (id=$id, session id=$sid") ;
            return ;
            }



        #print $sid, '  ' ;
        untie %sess ;

        %sess = () ;
        }

        {
        my %sess ;
        my $obj = tie (%sess, 'Apache::SessionX', $args2 && $args->{idfrom}?undef:$sid, {%stdargs, 'config' => $cfg, $args2?%$args:()}) or Error ("Cannot tie to Apache::SessionX") ;
        
        my $e = $errors ;
        Check (\%sess, 'A' . $num, 1 + $num * 2) ;
        Check (\%sess, 'B' . $num, 2 + $num * 2) ;

        my $nid ;
        ($init, $nid, $mod) = $obj -> getids ;
        if ($args -> {newid} && $nid eq $sid)
            {
            Error ("is not a newid, id didn't change (old id=$sid, init id=$init") ;
            return ;
            }




        print "ok\n" if ($e == $errors) ;
        untie %sess ;
        }
    }


sub simpletest

    {
    local $SIG{ALRM} = sub { Error ("Time out. Locking not working properly") } ;    
    alarm $timeout if (!$win32) ;
    dosimpletest (@_) ;
    alarm 0  if (!$win32) ;
    }


sub dopersisttest

    {
    my ($num, $msg, $cfg, $args, $args2, $id) = @_ ;

    my $sid ;
    my $init ;
    my $mod ;

    printf ('#%02d %-30s', $num, "$msg...") ;
        {
        my %sess ;
        my $obj = tie (%sess, 'Apache::SessionX', undef, { %stdargs, 'config' => $cfg, %$args})  or Error ("Cannot tie to Apache::SessionX") ;
        
        if ($args -> {lazy} && $obj -> getid)
            {
            Error ("is not lazy, id is not undef before access") ;
            return ;
            }
        elsif (!$args -> {lazy} && !$obj -> getid)
            {
            Error ("id is missing") ;
            return ;
            }
            


        $sess{'A' . $num} = 1 + $num * 2;
        $sess{'B' . $num} = 2 + $num * 2;

        $sid = $obj -> getid ;

        if (($args -> {newid} || $args -> {recreate_id}) && $id && $id eq $sid)
            {
            Error ("id should have changed, but didn't (id=$id, session id=$sid") ;
            return ;
            }
        elsif (!($args -> {newid} || $args -> {recreate_id}) && $id && $id ne $sid)
            {
            Error ("id has changed, but should be the same (id=$id, session id=$sid") ;
            return ;
            }


        $obj -> cleanup ;
        
        if ($obj -> getid)
            {
            Error ("id should be empty after cleanup") ;
            return ;
            }

        if ($args -> {idfrom})
            {
            $obj -> setidfrom ($args -> {idfrom}) ;
            }
        else
            {
            $obj -> setid ($sid) ;
            }
        
        my $e = $errors ;
        Check (\%sess, 'A' . $num, 1 + $num * 2) ;
        Check (\%sess, 'B' . $num, 2 + $num * 2) ;

        $sess{'C' . $num} = 2 + $num * 2;

        my $nid = $obj -> getid ;

        if ($nid ne $sid)
            {
            Error ("id has changed, but should be the same 2 (new id=$nid, session id=$sid") ;
            return ;
            }

        ($init, $nid, $mod) = $obj -> getids ;
        if ($args -> {newid} && $nid eq $sid)
            {
            Error ("is not a newid, id didn't change (old id=$sid, init id=$init") ;
            return ;
            }

        $sid = $nid ;
        $nid = undef ;
        $obj -> cleanup ;
        
        if ($obj -> getid)
            {
            Error ("id should be empty after cleanup 2") ;
            return ;
            }

        if ($args -> {idfrom})
            {
            $obj -> setidfrom ($args -> {idfrom}) ;
            }
        else
            {
            $obj -> setid ($sid) ;
            }
        
        Check (\%sess, 'A' . $num, 1 + $num * 2) ;
        Check (\%sess, 'B' . $num, 2 + $num * 2) ;
        Check (\%sess, 'C' . $num, 2 + $num * 2) ;

        ($init, $nid, $mod) = $obj -> getids ;
        if ($args -> {newid} && (!$nid || $nid eq $sid))
            {
            Error ("is not a newid, id didn't change 2 (old id=$sid, init id=$init, new id = $nid ") ;
            return ;
            }

        print "ok\n" if ($e == $errors) ;
        untie %sess ;
        }
    }


sub persisttest

    {
    local $SIG{ALRM} = sub { Error ("Time out. Locking not working properly") } ;    
    alarm $timeout  if (!$win32) ;
    dopersisttest (@_) ;
    alarm 0  if (!$win32) ;
    }



sub dofailtest

    {
    my ($num, $msg, $cfg, $args, $id) = @_ ;

     printf ('#%02d %-30s', $num, "$msg...") ;
        {
        my %sess ;
        
        eval { tie (%sess, 'Apache::SessionX', $id, { %stdargs, 'config' => $cfg, %$args})  or Error ("Cannot tie to Apache::SessionX") ; } ;

        if ($@)
            {
            print "ok\n" ;
            }
        else
            {
            Error ("should fail") ;
            }
        }

   }

sub failtest

    {
    local $SIG{ALRM} = sub { Error ("Time out. Locking not working properly") ;  } ;    
    alarm $timeout  if (!$win32) ;
    dofailtest (@_) ;
    alarm 0  if (!$win32) ;
    }

sub preopen

    {
    my ($num, $msg, $cfg, $args, $id) = @_ ;

     printf ('#%02d %-30s', $num, "$msg...") ;
        {
        my %sess ;
        
        eval { tie (%sess, 'Apache::SessionX', $id, { %stdargs, 'config' => $cfg, %$args})  or Error ("Cannot tie to Apache::SessionX") ; } ;

        if (!$@)
            {
            print "ok\n" ;
            }
        else
            {
            Error ("failed $@") ;
            }
        }

   }



sub concurrent

    {
    my ($num, $msg, $cfg, $args, $id) = @_ ;

    my $cnt ; 

     printf ('#%02d %-30s', $num, "$msg...\n") ;

    my %sess ;
    my $obj ;
    eval { $obj = tie (%sess, 'Apache::SessionX', undef, { %stdargs, 'config' => $cfg, lazy => 1, create_unknown => 1, Transaction => 1})  or die ("Cannot tie to Apache::SessionX") ; } ;
    
    if ($@)
        {
        Error ("failed $@") ;
        return ;
        }
    $obj -> setidfrom ('counter') ;
    $sess{count} = 0 ;
    $obj -> cleanup ;


    for (my $n = 0; $n < $numprocs; $n++)
        {
        system ("$Config{perlpath} -MExtUtils::testlib testcount.pl '$cfg' " . chr($n + 65) . ' &') ;
        }


    my $lastcnt = -1 ;
    my $wait = 0 ;
    while (1)
    
        {
        $obj -> setidfrom ('counter') ;
        if (($cnt = $sess{count}) == $numprocs * 10)
            {
            print "\n... ok\n" ;
            return ;
            }
        $obj -> cleanup ;
        $wait = 0 if ($cnt != $lastcnt) ;
        $wait++ if ($cnt == $lastcnt) ;
        last if ($wait == 4) ;

        sleep 1 ;
        }

    print "\n" ;
    Error ("Count is $cnt should be " . ($numprocs * 10) . ". Looks like locking doesn't work correct") ;
    }






my $time = localtime ;
my $cfg ;
my %time ;

foreach $cfg (@tests)
    {
    my $osuser = $Apache::SessionX::Config::param{$cfg}{osuser} ;
    local $< ;
    local $> ;

    if ($osuser)
        {
        my $uid    = getpwnam($osuser) ;
        $< = $uid ;
        $> = $uid ;
        }


    print "\n** Testing configuration '$cfg': $Apache::SessionX::Config::param{$cfg}{Info}...\n" ;
    my $n = 0 ;

    preopen    ($n++, "o Open",                       $cfg, {}) ;

    my $t0 = eval { [gettimeofday()] } || [0] ;

    simpletest ($n++, "s No Args",                    $cfg, {}) ;
    simpletest ($n++, "s Lazy",                       $cfg, {lazy => 1}) ;
    failtest   ($n++, "f unknown id",                 $cfg, {}, 'aa') ;
    failtest   ($n++, "f unknown id",                 $cfg, {}, 'aa') ;
    failtest   ($n++, "f unknown idfrom",             $cfg, {idfrom => 'blabla' . $cfg . $time}) ;
    failtest   ($n++, "f unknown idfrom",             $cfg, {idfrom => 'blabla' . $cfg . $time}) ;
    simpletest ($n++, "s create_unknown",             $cfg, {create_unknown => 1}, 'aabb') ;
    simpletest ($n++, "s Idfrom, create_unknown, id", $cfg, {idfrom => 'blabla1' . $cfg . $time, create_unknown => 1}) ;
    simpletest ($n++, "s Idfrom, create_unknown",     $cfg, {idfrom => 'blabla2' . $cfg . $time, create_unknown => 1}, 1) ;
    simpletest ($n++, "s create_unknown, recreate",   $cfg, {recreate_id => 1, create_unknown => 1}, undef, 'aabbcc') ;
    simpletest ($n++, "s newid",                      $cfg, {newid => 1}, 1) ;
    simpletest ($n++, "s newid, lazy",                $cfg, {newid => 1, lazy => 1}, 1) ;
    simpletest ($n++, "s newid 2",                    $cfg, {newid => 1, create_unknown => 1}, 1, 'aabbcc') ;

    persisttest ($n++, "p Lazy",                       $cfg, {lazy => 1}) ;
    persisttest ($n++, "p create_unknown",             $cfg, {lazy => 1, create_unknown => 1}, 'aabb') ;
    persisttest ($n++, "p Idfrom, create_unknown, id", $cfg, {lazy => 1, idfrom => 'blabla3' . $cfg . $time, create_unknown => 1}) ;
    persisttest ($n++, "p Idfrom, create_unknown",     $cfg, {lazy => 1, idfrom => 'blabla4' . $cfg . $time, create_unknown => 1}, 1) ;
    persisttest ($n++, "p create_unknown, recreate",   $cfg, {lazy => 1, recreate_id => 1, create_unknown => 1}, undef, 'aabbcc') ;
    persisttest ($n++, "p newid",                      $cfg, {lazy => 1, newid => 1}, 1) ;
    persisttest ($n++, "p newid, lazy",                $cfg, {lazy => 1, newid => 1}, 1) ;
    persisttest ($n++, "p newid 2",                    $cfg, {lazy => 1, newid => 1, create_unknown => 1}, 1, 'aabbcc') ;

    my $t1 = eval { [gettimeofday()] } || [0] ;

    concurrent ($n++, "c concurrent access",          $cfg) ;

    print "** ", $time{$cfg} = eval { tv_interval ($t0, $t1) } || 0 , "s\n" ;

    my $mgr = Apache::SessionX::Manager -> new ({config => $cfg}) ;
    my $id ;
    my $cnt = eval { $mgr -> count_sessions ; } ;
    if (!$@)
	{
    	print "Found $cnt sessions\n" ;
    	my $cnt2 = 0 ;
    	while ($id = $mgr -> next_session_id)
            {
            #print $id, "\n" ;
            $cnt2++ ;
            }

        Error ("count_sessions ($cnt) and next_session_id ($cnt2) counts differs") if ($cnt != $cnt2) ;
        }
    else
        {
	print "SessionManager not supported by $cfg\n" ;
	}
    }

if ($errors)
    {
    print "Found $errors ERRORS\n" ;
    }
else
    {
    print "All tests successfull\n" ;
    }

