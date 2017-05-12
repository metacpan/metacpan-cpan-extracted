#!/usr/bin/perl -I./t

$| = 1;
print "1..$::tests\n";

require DBI;
use strict;
use testenv;

my (@row);

my ($dsn, $user, $pass) = soluser();
print "ok 1\n";

my $dbh = DBI->connect($dsn, $user, $pass, {PrintError => 0}); 
print "not " unless($dbh);
print "ok 2\n";
exit(1) unless($dbh);

#### testing Tim's early draft DBI methods

my $foo = $DBI::errstr;		# suppress possible typo warnings
   $foo = $DBI::err;
   $foo = $DBI::state;
   $foo = $DBI::VERSION;

my ($t);
$t = 3;
$t = test_autocommit_init($dbh, $t);	# 3
$t = test_rows($dbh, $t);		# 4
$t = test_err($dbh, $t);		# 5
$t = test_errstr($dbh, $t);		# 6..8
$t = test_state($dbh, $t);		# 9

$dbh->disconnect();

BEGIN { $::tests = 9; }

sub test_autocommit_init
    {
    my ($dbh, $test) = (@_);
    print " Test $test: initial AutoCommit\n";

    print "not " unless $dbh->{AutoCommit};
    print "ok $test\n";
    ++$test;
    }

sub test_rows
    {
    my ($dbh, $test) = (@_);
    print " Test $test: rows attribute\n";
    my ($sth, $rows);

    $sth = $dbh->prepare("select count(*) from perl_dbd_test");
    $sth->execute();
    ($rows) = $sth->fetchrow;
    print " rows to delete: $rows\n";
    $sth->finish();

    $dbh->{AutoCommit} = 0;
    $sth = $dbh->prepare("DELETE FROM perl_dbd_test");
    $sth->execute();
    print " $DBI::rows rows deleted\n";
    print "not " unless($sth->rows > 0 
		    && $DBI::rows == $sth->rows);
    $sth->finish();
    $dbh->rollback();
    print "ok $test\n";
    ++$test;
    }

sub test_err
    {
    my ($dbh, $test) = (@_);
    print " Test $test: err attribute\n";

    my ($sth, @row);
    $sth = $dbh->prepare('SELECT x FROM perl_dbd_test WHERE 1 = 0');

    print "not " unless ($DBI::err == 13
			 && $dbh->err == $DBI::err);
    print "ok $test\n";
    ++$test;

    $test;
    }

sub test_errstr
    {
    my ($dbh, $test) = (@_);
    my $expectedErr = 'Table name PERL_DBD_TEST conflicts with an existing'
                      . ' entity';
    print " Test $test: errstr attribute\n";

    my ($sth, @row);
    $sth = $dbh->prepare('CREATE TABLE perl_dbd_test( A INTEGER )');
    $sth->execute();

    print " err=", $sth->err, " errstr=", $sth->errstr, "\n";

    print "not " unless ($sth->errstr =~ /$expectedErr/);
    print "ok $test\n";
    ++$test;

    $sth->execute();
    print "not " unless ($DBI::errstr =~ /$expectedErr/);
    print "ok $test\n";
    ++$test;

    $sth->execute();
    print "not " unless ($dbh->errstr =~ /$expectedErr/);
    print "ok $test\n";
    ++$test;

    $sth->finish();
    $test;
    }
sub test_state
    {
    my ($dbh, $test) = (@_);
    print " Test $test: state attribute\n";

    my ($sth, @row);
    $sth = $dbh->prepare('SELECT * FROM perl_dbd_test WHERE 1 = ?');
    $sth->execute('foobar');

    print " err=", $sth->err, " state=", $dbh->state,"\n";
    
#    print "not " if ($dbh->state != 22005
#    		     || $DBI::state != 22005
#		     || ($DBI::VERSION gt '0.82' && $sth->state != 22005));
    
    print "not " if ( $dbh->state ne '07006'
                  || $DBI::state ne '07006'
                  || ($DBI::VERSION gt '0.82' && $sth->state ne '07006') );
    
    $sth->finish();
    print "ok $test\n";
    ++$test;
    }
__END__
