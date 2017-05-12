#!perl

use strict;
use warnings;

use Test::More tests => 17;

SKIP: {
  skip "mysql tests: TEST_MYSQL is false", 17 unless $ENV{TEST_MYSQL};

  my $class = 'Class::DBI::Replicated::Test::mysql';
  
  use_ok($class);
  
  my $buf = [];
  my $oldsize;
  
  $class->repl_output($buf);
  
  $class->search(id => 0);
  is($buf->[-1], "repl_db db_Slave_localhost",
     "pre-write SELECT used slave");
  
  $class->create({
    name => 'test 1',
  });
  
  is($buf->[-3], "repl_db db_Master",
     "INSERT used master");
  is($buf->[-1], "repl_mark",  
     "INSERT marked position");
  
  my ($obj) = $class->search(name => 'test 1');
  
  is($buf->[-3], "repl_db db_Master",
     "post-write SELECT used master");
  is($buf->[-2], "repl_check",
     "SELECT triggered check");
  is($buf->[-1], "switch_to_slave localhost",
     "SELECT switched back to slave");
  
  $class->wait_for_slave;
  
  # not sure this test needs to be here, since the SELECT
  # already did this
  is($buf->[-1], "switch_to_slave localhost",
     "waiting for slave");
  
  $obj = $class->retrieve($obj->id);
  
  is($buf->[-1], "repl_db db_Slave_localhost",
     "SELECT used slave");
  
  $oldsize = @$buf;
  $obj = $class->retrieve($obj->id);
  
  is($buf->[-1], "repl_db db_Slave_localhost",
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
  
  $class->drop_table;
  
  is($buf->[-1], "repl_db db_Master",
     "DROP TABLE used master");
}
