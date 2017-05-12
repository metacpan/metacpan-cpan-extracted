#!/usr/bin/perl -I./t

$| = 1;
print "1..$::tests\n";

require DBI;
use strict;
use testenv;

my (@row);

my ($dsn, $user, $pass) = soluser();
print "ok 1\n";

my $dbh = DBI->connect($dsn, $user, $pass); 
print "not " unless($dbh);
print "ok 2\n";
exit(1) unless($dbh);

#### testing all those fetch methods

my ($t);
$t = 3;
$t = test_bind_col($dbh, $t);		# 3..4
$t = test_bind_col2($dbh, $t);		# 5
$t = test_fetch($dbh, $t);		# 6
$t = test_chopblank($dbh, $t);		# 7
$t = test_fetch_hash($dbh, $t);		# 12 ?
$dbh->disconnect();


BEGIN { $::tests = 12; }

sub test_bind_col2
    {
    my ($dbh, $test) = (@_);
    print " Test $test: bind_columns after prepare\n";

    my ($sth, @row, $ok);
    my ($a, $b);

    $ok = 1;
    $sth = $dbh->prepare('SELECT A,B FROM perl_dbd_test')
    	or $ok = 0;
    if ($ok)
        {
        $sth->bind_columns(undef, \($a, $b))
    	    or $ok = 0;
	}
    if ($ok)
        {
        $sth->execute() 
    	    or $ok = 0;
	}
    $sth->finish();
    print "not " unless($ok);
    print "ok $test\n";
    ++$test;
    }
sub test_bind_col
    {
    my ($dbh, $test) = (@_);
    print " Test $test: bind_col & fetch\n";

    my ($sth, @row);
    my ($a, $b);
    $sth = $dbh->prepare('SELECT A,B FROM perl_dbd_test');
    $sth->execute();
    while (@row = $sth->fetchrow())
        {
        print " \@row     a,b:", $row[0], ",", $row[1], "\n";
        }
    $sth->finish();

    $sth->execute();
    $sth->bind_col(1, \$a);
    $sth->bind_col(2, \$b);
    while ($sth->fetch())
        {
        print " bind_col a,b:", $a, ",", $b, "\n";
        unless (defined($a) && defined($b))
    	    {
	    print "not ";
	    last;
	    }
        }
    print "ok $test\n";
    ++$test;
    $sth->finish();

    print " Test $test: bind_columns & fetch\n";
    ($a, $b) = (undef, undef);
    $sth->execute();
    $sth->bind_columns(undef, \$b, \$a);
    while ($sth->fetch())
        {
        print " bind_columns a,b:", $b, ",", $a, "\n";
        unless (defined($a) && defined($b))
    	    {
	    print "not ";
	    last;
	    }
        }
    print "ok $test\n";
    ++$test;
    }

sub test_fetch_hash
    {
    my ($dbh, $test) = (@_);
    print " Test $test: fetchhash\n";

    my ($sth, @row, $href, $expect);
    my ($a, $b);
    $sth = $dbh->prepare('SELECT A,B FROM perl_dbd_test');
    $sth->execute();

    @row = $sth->fetchrow_array();
    $expect->{'A'} = shift @row;
    $expect->{'B'} = shift @row;
    $sth->finish();

    $sth->execute();
    print " cols: ", join(",", @{$sth->{NAME}}), "\n";
    my $x = sub {
    	my $sth= shift @_;
        print " cols: ", join(",", @{$sth->{NAME}}), "\n";
	};
    &{$x}($sth);

    $href = $sth->fetchrow_hashref();

    print "not " unless ($expect->{'A'} eq $href->{'A'}
    			 && $expect->{'B'} eq $href->{'B'});
    $sth->finish();
    print "ok $test\n";
    ++$test;
    }
sub test_fetch
    {
    my ($dbh, $test) = (@_);
    print " Test $test: \$aref = fetch\n";

    my ($sth, @row, $aref);
    my ($a, $b);
    $sth = $dbh->prepare('SELECT A,B FROM perl_dbd_test');
    $sth->execute();

    @row = $sth->fetchrow_array();
    $sth->finish();

    $sth->execute();
    print "not " unless (($aref = $sth->fetchrow_arrayref())
    	                 && $row[0] == $aref->[0]
	                 && $row[1] eq $aref->[1]);
    $sth->finish();
    print "ok $test\n";
    ++$test;
    }
sub test_chopblank
    {
    my ($dbh, $test) = (@_);
    my ($chop);
    my ($sth, $row, $aref);
    my $tests = 5;
    print " Test $test: ChopBlanks (preparing)\n";
    $chop = $dbh->{ChopBlanks};
    my ($chopped, $unchopped);

    my $skip = sub 
    	{
	my ($test, $tests) = @_;
	while ($tests--)
	    {
	    print "ok $test\n";
	    $test++;
	    }
	return $test;
	};

    my $try = sub 
        {
	my ($dbh, $sth, $row);
	$dbh = shift @_;
        $chop = shift @_;

        $sth = $dbh->prepare('SELECT A,B FROM perl_dbd_test')
		or return undef;

	if (defined($chop))
	    {
	    $sth->{ChopBlanks} = $chop;
	    print " set chop = ", $chop ? 'TRUE' : 'FALSE', "\n";
	    $chop = $sth->{ChopBlanks};
	    print " get chop = ", $chop ? 'TRUE' : 'FALSE', "\n";
	    }

        $sth->execute()
		or return undef;
        $row = $sth->fetch()
		or return undef;
        $sth->finish()
		or return undef;
	$row;
	};

    $dbh->{ChopBlanks} = 0;
    $row = &{$try}($dbh); 
    $unchopped = $chopped = $row->[1];
    $chopped =~ s/ +$//;
    if ($chopped eq $unchopped)
	{
	warn("no test data - skipping");
	&{$skip}($test, $tests);
	return $test + $tests;
	}
    print "ok $test\n";
    ++$test;
    --$tests;


    print " Test $test: ChopBlank=ON via dbh\n";
    $dbh->{ChopBlanks} = 1;
    $row = &{$try}($dbh);
    print "not " if ($row->[1] ne $chopped
    		    );
    print "ok $test\n";
    ++$test;
    --$tests;
    
    print " Test $test: ChopBlank=OFF via dbh\n";
    $dbh->{ChopBlanks} = 0;
    $row = &{$try}($dbh);
    print "not " unless ($row->[1] eq $unchopped
    		        );
    print "ok $test\n";
    ++$test;
    --$tests;

    print " Test $test: ChopBlank=ON via sth\n";
    $row = &{$try}($dbh, 1);
    print "not " if ($row->[1] ne $chopped
    		    );
    print "ok $test\n";
    ++$test;
    --$tests;

    print " Test $test: ChopBlank=OFF via sth\n";
    $row = &{$try}($dbh, 0);
    print "not " unless ($row->[1] eq $unchopped
    		        );
    print "ok $test\n";
    ++$test;
    --$tests;

    $test;
    }
__END__
