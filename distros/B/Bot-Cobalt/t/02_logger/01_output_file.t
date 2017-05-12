use Test::More;
use strict; use warnings;

use Path::Tiny;
use Try::Tiny;

my $this_class = 'Bot::Cobalt::Logger::Output::File';

my $test_log_path = Path::Tiny->tempfile(CLEANUP => 1);

use_ok( $this_class );

eval {; $this_class->new };
ok $@, 'new() with no args dies';

my $output = new_ok( $this_class => [
    file => $test_log_path,
  ],
);

is( $output->file, $test_log_path, 'file() returns log path' );

is( $output->perms, 0666, 'perms() returned 0666' );

ok( $output->_write("This is a test string"), '_write()' );

ok( -e $test_log_path, 'Log file was created' );

my $contents = do { local (@ARGV, $/) = $test_log_path ; <> };

chomp $contents;
cmp_ok( $contents, 'eq', "This is a test string" );

## FIXME test mode / perms ?

$test_log_path->remove
  or warn "temporary log at $test_log_path disappeared before unlink";

ok( 
  $output->_write("Testing against fresh log"), 
  '_write() after unlink()'
);

ok( -e $test_log_path, 'Log file was recreated' );

$contents = $test_log_path->slurp;
chomp $contents;
cmp_ok( $contents, 'eq', "Testing against fresh log" );

done_testing
