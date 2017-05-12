use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw'GET_BODY GET POST';
use File::Spec;

{
  my $f;
  sub t_start_error_log_watch {
    my $name=File::Spec->catfile( Apache::Test::vars->{t_logs}, 'error_log' );
    open $f, "$name" or die "ERROR: Cannot open $name: $!\n";
    seek $f, 0, 2;
  }

  sub t_finish_error_log_watch {
    local $/="\n";
    my @lines=<$f>;
    undef $f;
    return @lines;
  }
}

sub t_read_file {
  local $/;
  open my $f, '<'.$_[0] or die "ERROR: Cannot open $_[0]: $!\n";
  return scalar <$f>;
}

plan tests => 26;

my ($res, $session, $store);

Apache::TestRequest::module('UAExceptionsFile');

t_rmtree('t/store');

$session=GET_BODY( "/TestSession__001session_generation?SESSION" );
$session=~s/SESSION=//; chomp( $session );

t_debug( "using session $session" );

t_client_log_error_is_expected(2);
t_start_error_log_watch;
$res=GET( "/store?a=set;s=$session;k=klaus;v=value" );
select undef, undef, undef, .5;	# sleep for a while
my @errors=grep {/\[error\]/} t_finish_error_log_watch();
ok t_cmp( $errors[0],
	  qr/\[Apache2::ClickPath::Store\] Cannot create directory/,
	  'check for correct error message in error_log' );
ok t_cmp( $errors[1],
	  qr!\[Apache2::ClickPath::Store\] .*/#lastcleanup: !,
	  'check for correct error message in error_log' );

ok t_cmp( $res->code, 500, 'set returns code 500' );

t_mkdir('t/store');

t_start_error_log_watch;
$res=GET( "/store?a=set;s=$session;k=klaus;v=value" );
ok t_cmp( [grep /\[Apache2::ClickPath::Store\] Cannot create/, t_finish_error_log_watch()],
	  [],
	  'this time no error should occur' );

ok t_cmp( $res->content, "ok", 'set returns "ok"' );

ok t_cmp( $res->code, 200, 'set returns code 200' );

ok t_cmp( t_read_file( "t/store/$session/klaus" ), 'value',
	  'value stored' );

$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->content, 'value', 'get stored value' );
ok t_cmp( $res->code, 200, 'get returns code 200' );

$res=GET( "/store?a=get;s=$session;k=otto" );
ok t_cmp( $res->code, 404, 'get returns code 404' );

Apache::TestRequest::user_agent( reset=>1, keep_alive=>300 );
$res=GET( "/store?a=get;s=$session;k=klaus" );
sleep 3;
$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->code, 200, 'no timeout yet' );

sleep 3;
Apache::TestRequest::user_agent( reset=>1, keep_alive=>0 );
sleep 1;
ok t_cmp( -d "t/store/#$session", 1, 'session marked for deletion (renamed)' );

$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->code, 404, 'data not accessible' );

sleep 3;
$res=GET( "/store?a=get;s=$session;k=klaus" ); # let cleanup() run once again
sleep 1;			# and give it time to accomplish the task
$res=GET( "/store?a=get;s=$session;k=klaus" );
$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->code, 404, 'session store deleted => NOT_FOUND' );
ok t_cmp( -d "t/store/#$session", undef, 'session directory deleted' );

Apache::TestRequest::user_agent( reset=>1 ); # close the kept alive connection

Apache::TestRequest::module('Secret');

$session=GET_BODY( "/TestSession__001session_generation?SESSION" );
$session=~s/SESSION=//; chomp( $session );

t_debug( "using session $session" );

$res=GET( "/store?a=set;s=$session;k=klaus;v=value" );

ok t_cmp( $res->content, "ok", 'set returns "ok" (Secret)' );

ok t_cmp( $res->code, 200, 'set returns code 200 (Secret)' );

ok t_cmp( t_read_file( "t/store/$session/klaus" ), 'value',
	  'value stored (Secret)' );

$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->content, 'value', 'get stored value (Secret)' );
ok t_cmp( $res->code, 200, 'get returns code 200 (Secret)' );

$res=GET( "/store?a=get;s=$session;k=otto" );
ok t_cmp( $res->code, 404, 'get returns code 404 (Secret)' );

Apache::TestRequest::user_agent( reset=>1, keep_alive=>300 );
$res=GET( "/store?a=get;s=$session;k=klaus" );
sleep 3;
$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->code, 200, 'no timeout yet (Secret)' );

sleep 3;
Apache::TestRequest::user_agent( reset=>1, keep_alive=>0 );
sleep 1;
ok t_cmp( -d "t/store/#$session", 1,
	  'session marked for deletion (renamed) (Secret)' );

$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->code, 404, 'data not accessible (Secret)' );

sleep 2;
$res=GET( "/store?a=get;s=$session;k=klaus" ); # let cleanup() run once again
sleep 1;			# and give it time to accomplish the task
$res=GET( "/store?a=get;s=$session;k=klaus" );
ok t_cmp( $res->code, 404, 'session store deleted => NOT_FOUND (Secret)' );
ok t_cmp( -d "t/store/#$session", undef,
	  'session directory deleted (Secret)' );

Apache::TestRequest::user_agent( reset=>1 ); # close the kept alive connection
sleep 3;			# and give the server time to cleanup and
				# prevent a warning if t/store is removed
				# before the server has finished it's cleanup

# Local Variables: #
# mode: cperl #
# End: #
