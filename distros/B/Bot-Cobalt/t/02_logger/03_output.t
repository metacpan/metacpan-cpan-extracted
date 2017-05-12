use Test::More;
use strict; use warnings FATAL => 'all';

use Path::Tiny;
use Try::Tiny;

my $this_class = 'Bot::Cobalt::Logger::Output';

my $test_log_path = Path::Tiny->tempfile(CLEANUP => 1);

use_ok( $this_class );

my $output = new_ok( $this_class );

ok( $output->time_format, 'has time_format' );
ok( $output->log_format,  'has log_format' );

eval {; $output->add };
ok $@, "add() dies with no args";
eval {; $output->add(1) };
ok $@, "add() dies with odd args";

ok( 
  $output->add(
    myfile => {
      type => 'File',
      file => $test_log_path,
    },
    
    myterm => {
      type => 'Term',
    },
  ),
  'add() file and term'
);

my $stdout;
{
  local *STDOUT;
  open STDOUT, '>', \$stdout
    or die "Could not reopen STDOUT: $!";

  ok( 
    $output->_write('info', [caller(0)], "Testing", "things"), 
    '_write()' 
  );

  close STDOUT
}

ok( $stdout, "Logged to STDOUT" );

ok( 
  do { local (@ARGV, $/) = $test_log_path; <> }, 
  "Logged to File"
);

## FIXME test with modified time_format / log_format ?

my $tobj;
ok( $tobj = $output->get('myterm'), 'get()' );
isa_ok( $tobj, 'Bot::Cobalt::Logger::Output::Term' );

cmp_ok( $output->del('myterm', 'myfile'), '==', 2, 'del() 2 objects' );

done_testing
