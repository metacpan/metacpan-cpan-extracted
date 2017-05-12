use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

sub cmdline {
  my $pid=shift || $$;
  open my $f, "/proc/$pid/cmdline";
  local $/;
  my $rc=<$f>;
  $rc=~s/\0+$//;
  $rc=~s/\0/ /g;
  return $rc;
}

plan tests => 2;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

my $line=GET_BODY( "/TestStat__1pid" );
my ($ppid, $pid, $rest)=split /:/, $line, 3;
t_debug( "pid=$pid, req=$rest\n" );

ok t_cmp( $rest, 'httpd: GET /TestStat__1pid HTTP/1.0', 'cmdline during req' );
sleep 1;			# give the server time to do it's cleanup
ok t_cmp( cmdline( $pid ), cmdline( $ppid ), 'cmdline after req' );

## Local Variables: ##
## mode: cperl ##
## End: ##
