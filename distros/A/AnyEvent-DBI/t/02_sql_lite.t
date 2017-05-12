#!/usr/bin/perl

BEGIN {
   unless ($ENV{PERL_ANYEVENT_DBI_TESTS}) {
      print "1..0 # SKIP env var PERL_ANYEVENT_DBI_TESTS not set\n"; exit;
   }
   eval {
      require DBD::SQLite;
   };
   if ($@) {
      print "1..0 # SKIP this test requires Test::More and DBD::SQLite\n"; exit;
   }
   require Test::More;
   import Test::More tests => 43;
}

use strict;
use warnings;
use AnyEvent;
use AnyEvent::DBI;
use File::Temp qw(tempfile);

# we are going to watch what the sub-processes send to stderr
close STDERR;
my($tfh_err,$tfn_err) = tempfile;
close $tfh_err;
open(STDERR,">>$tfn_err");

my ($cv,$dbh,$tfh,$tfn,$error,$result,$rv);

($tfh,$tfn) = tempfile;
close $tfh;

# connect with exec
$cv  = AnyEvent->condvar;
$dbh = new AnyEvent::DBI(
   "dbi:SQLite:dbname=$tfn",'','',
   AutoCommit  => 1,
   PrintError  => 0,
   timeout     => 2,
   exec_server => 1,
   on_error    => sub { },
   on_connect  => sub {return $cv->send($@) unless $_[1]; $cv->send()},
);
$error = $cv->recv();
is($error,undef,'on_connect() called without error, sqlite server is connected');

# lets have an error
$cv = AnyEvent->condvar;
$dbh->exec('select bogus_column from no_such_table',sub {return $cv->send($@) unless $_[1];$cv->send(undef,$_[1])});
($error,$result) = $cv->recv();
like ($error,qr{no such table}i,'Select from non existant table results in error');
# ensure we got no stderr output
ok(-z $tfn_err,'Error does not result in output on STDERR');

# check the error behavior
$cv = AnyEvent->condvar;
$dbh->attr('PrintError',sub {return $cv->send($@) unless $_[1]; $cv->send(undef,$_[1])});
($error,$result)= $cv->recv();
ok(!$error,'No errors occur while checking attribute');
ok(!$result,'Accessor without set (PrintError) returns false');

# change the error behavior
$cv = AnyEvent->condvar;
$dbh->attr(PrintError=>1,sub {return $cv->send($@) unless $_[1]; $cv->send(undef,$_[1])});
($error,$result)= $cv->recv();
ok(!$error,'No error occurs while setting PrintError => 1');
ok($result,'Accessor with set (PrintError) returns true');

# check the error behavior
$cv = AnyEvent->condvar;
$dbh->attr('PrintError',sub {return $cv->send($@) unless $_[1]; $cv->send(undef,$_[1])});
($error,$result)= $cv->recv();
ok(!$error,'No errors occur while checking attribute');
ok($result,'PrintError was true');

# lets have an error
$cv = AnyEvent->condvar;
$dbh->exec('select bogus_column from no_such_table',sub {return $cv->send($@) unless $_[1];$cv->send(undef,$_[1])});
($error,$result) = $cv->recv();
like ($error,qr{no such table}i,'Select from non existant column makes an error');
# ensure we did get STDERR output
ok(-s $tfn_err,'Error message has appeared on STDERR');

# create a table
$cv = AnyEvent->condvar;
$dbh->exec('create table a_table (a_column text)',sub {return $cv->send($@) unless $_[1];$cv->send(undef,$_[1])});
($error,$result) = $cv->recv();
ok(!$error,'No errors creating a table');

# add some data
$cv = AnyEvent->condvar;
$dbh->exec('insert into a_table (a_column) values(?)','test',sub {return $cv->send($@) unless $#_;$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv();
ok(!$error,'No errors inserting into table');
is($rv,1,"One row affected");

# check for the data
$cv = AnyEvent->condvar;
$dbh->exec('select a_column from a_table',sub {return $cv->send($@) unless $#_;$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv();
ok(!$error,'No errors inserting into table');
ok($rv,'select succeeded');
is($result->[0]->[0],'test','found correct data');

# check the autocommit behavior
$cv = AnyEvent->condvar;
$dbh->attr('AutoCommit',sub {return $cv->send($@) unless $_[1]; $cv->send(undef,$_[1])});
($error,$result)= $cv->recv();
ok(!$error,'No errors occur while checking attribute');
ok($result,'AutoCommit was true');

# turn off autocommit
$cv = AnyEvent->condvar;
$dbh->attr(AutoCommit=>0,sub {return $cv->send($@) unless $_[1]; $cv->send(undef,$_[1])});
($error,$result)= $cv->recv();
ok(!$error,'No error setting attr');
ok(!$result,'AutoCommit was false');

# add some data
$cv = AnyEvent->condvar;
$dbh->exec('insert into a_table (a_column) values(?)','moredata',sub {return $cv->send($@) unless $#_;$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv;
ok(!$error,'No errors inserting into table');
is($rv,1,"One row affected");

# crash the handle
unlink $dbh;

# connect without exec or autocommit
$cv  = AnyEvent->condvar;
$dbh = new AnyEvent::DBI(
   "dbi:SQLite:dbname=$tfn",'','',
   AutoCommit  => 0,
   PrintError  => 0,
   timeout     => 2,
   exec_server => 0,
   on_error    => sub { },
   on_connect  => sub {return $cv->send($@) unless $_[1]; $cv->send()},
);
$error = $cv->recv();
is($error,undef,'on_connect() called without error, sqlite server is connected');

# check for the data and that the aborted transaction did not make it to the database
$cv = AnyEvent->condvar;
$dbh->exec('select a_column from a_table',sub {return $cv->send($@) unless $_[1];$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv();
ok(!$error,'No errors selecting from table');
ok($rv,'select succeeded');
is(scalar @$result,1,'found only one row');
is($result->[0]->[0],'test','found correct data in that row');

# add some data
$cv = AnyEvent->condvar;
$dbh->exec('insert into a_table (a_column) values(?)','moredata',sub {return $cv->send($@) unless $#_;$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv();
ok(!$error,'No errors inserting into table');
is($rv,1,'One row affected');

# commit to db
$cv = AnyEvent->condvar;
$dbh->commit(sub {return $cv->send($@) unless $_[1];$cv->send(undef,$_[1])});
($error,$result) = $cv->recv();
ok(!$error,'No errors commiting');

# check for the data and that the aborted transaction did not make it to the database
$cv = AnyEvent->condvar;
$dbh->exec('select a_column from a_table',sub {return $cv->send($@) unless $_[1];$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv();
ok(!$error,'No errors inserting into table');
ok($rv,'select succeeded');
is(scalar @$result,2,'found two rows');
is($result->[0]->[0],'test','found correct data in row one');
is($result->[1]->[0],'moredata','found correct data in row two');

# change the autocommit behavior
$cv = AnyEvent->condvar;
$dbh->attr(AutoCommit=>1,sub {return $cv->send($@) unless $_[1]; $cv->send(undef,$_[1])});
($error,$result)= $cv->recv();
ok(!$error,'No error occurs while setting AutoCommit => 1');
ok($result,'Accessor with set (AutoCommit) returns true');

# using bad function returns error
$cv = AnyEvent->condvar;
#$dbh->exec('select a_column from a_table where instr(a_column,?)','re',sub {return $cv->send($@) unless $_[0];$cv->send(undef,@_[1,2]);});
$dbh->exec('select a_column from a_table where instr(a_column,?)','re',
           sub {return $cv->send($@,@_[0,1,2]);});
my $hdl;
($error,$hdl,$result,$rv) = $cv->recv();
like($error,qr{function}i,'Using an unknown function results in error');

# create the function
$cv = AnyEvent->condvar;

$dbh->func(
   q{
      'instr',
      2,
      sub {
         my ($string, $search) = @_;
         return index $string, $search;
      },
   },
   'create_function',
   sub {return $cv->send($@) unless $_[1];$cv->send(undef,$_[1])}
);
$cv->recv(); # ignore result from this particular private fn.

# using new function
$cv = AnyEvent->condvar;
$dbh->exec('select a_column from a_table where instr(a_column,?) >= 0','re',sub {return $cv->send($@) unless $_[1];$cv->send(undef,@_[1,2])});
($error,$result,$rv) = $cv->recv();
ok(!$error,'Our new function works fine');
ok($rv,'select succeeded');
is(scalar @$result,1,'found only one row');
is($result->[0]->[0],'moredata','found correct data');

END {
   unlink $tfn if $tfn;
#   system ("cat $tfn_err");
   unlink $tfn_err if $tfn_err;
}

