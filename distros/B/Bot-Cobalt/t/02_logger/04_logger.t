use Test::More;
use strict; use warnings;

use Path::Tiny;
use Try::Tiny;

my $this_class = 'Bot::Cobalt::Logger';

my $test_log_path = Path::Tiny->tempfile(CLEANUP => 1);

use_ok( $this_class );

eval {; $this_class->new };
ok $@, 'new() with no args dies';

eval {;  $this_class->new(level => 'abcd') };
ok $@, 'new() with invalid level arg dies';

my $logobj = new_ok( $this_class => [
    level => 'info',
  ],
);

## We're in 'info', shouldn't log debug.
ok( ! $logobj->_should_log('debug'), 'should not log debug()' );
ok( $logobj->_should_log('info'), 'should log info()' );
ok( $logobj->_should_log('warn'), 'should log warn()' );
ok( $logobj->_should_log('error'), 'should log error()' );

## Reset level()
ok( $logobj->set_level('warn'), 'set_level warn' );
ok( $logobj->level eq 'warn', 'level is warn' );
ok( ! $logobj->_should_log('info'), 'should not log info()' );

## Manipulate output() object

isa_ok( $logobj->output, 'Bot::Cobalt::Logger::Output' );
ok(
  $logobj->output->add(
    myfile => {
      type => 'File',
      file => $test_log_path,
    },
  ),
  'add() file output class'
);

can_ok( $logobj,
  qw/
    debug
    info
    warn
    error
  /,
);

ok( $logobj->set_level('debug'), 'set_level debug' );
ok( $logobj->debug("Testing", "debug"), 'debug()' );
ok( $logobj->info("Testing", "info"), 'info()' );
ok( $logobj->warn("Testing", "warn"), 'warn()' );
ok( $logobj->error("Testing", "error"), 'error()' );

my $contents = do { local (@ARGV, $/) = $test_log_path ; <> };

cmp_ok( split(/\n/, $contents), '==', 4, 'logfile has expected line count' );

unlink $test_log_path;

## FIXME
##  test caller details
##  test log_format / time_format triggers and constructor opts
##   (output obj's settings should change also)

done_testing
