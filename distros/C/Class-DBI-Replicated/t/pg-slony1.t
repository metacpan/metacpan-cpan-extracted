#!perl

use strict;
use warnings;

use Test::More tests => 15;

SKIP: {
  skip "pg tests: TEST_PG is false", 15 unless $ENV{TEST_PG};

  my $class = 'Class::DBI::Replicated::Test::Pg::Slony1';

  use_ok($class);

  my $buf = [];
  my $oldsize;

  $class->repl_output($buf);

  $class->db_Master->do(<<'');
DELETE FROM repl_test;

         $class->search(id => 0);
  is($buf->[-1], "repl_db db_Slave_slave1",
     "pre-write SELECT used slave");

  $class->create({
    name => 'test 1',
  });

  is($buf->[-3], "repl_db db_Master",
     "INSERT used master");
  is($buf->[-1], "repl_mark",  
     "INSERT marked position");

  my ($obj) = $class->search(name => 'test 1');

  is $buf->[-1], "repl_check", "SELECT triggered check";
  pop @{$buf} while $buf->[-1] eq "repl_check";
  is($buf->[-1], "repl_db db_Master",
     "post-write SELECT used master");
  #is($buf->[-1], "switch_to_slave slave1",
  #   "SELECT switched back to slave");
  
  $class->wait_for_slave;

  # for Pg, the SELECT will almost certainly not have done this
  is($buf->[-1], "switch_to_slave slave1",
     "waiting for slave");
  $obj = $class->retrieve($obj->id);

  is($buf->[-1], "repl_db db_Slave_slave1",
     "SELECT used slave");

  $oldsize = @$buf;
  $obj = $class->retrieve($obj->id);

  is($buf->[-1], "repl_db db_Slave_slave1",
     "SELECT used slave");
  is(scalar @$buf, $oldsize + 1,
     "no extra repl_check was done");

  $obj->flavor('Zesty');
  $obj->update;

  is($buf->[-3], 'switch_to_master',
     "UPDATE switched to master");
  is($buf->[-2], 'repl_db db_Master');
  is($buf->[-1], 'repl_mark');

  $obj->delete;

  isnt($buf->[-3], 'switch_to_master',
       'DELETE did not call for another switch');
  is($buf->[-1], "repl_mark",
     "DELETE did repl_mark again");
}
