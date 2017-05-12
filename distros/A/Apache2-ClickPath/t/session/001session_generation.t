use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
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

plan tests => 26;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=.+/m,  ), "SESSION exists";

ok t_cmp( GET_BODY( "/TestSession__001session_generation?CGI_SESSION" ),
	  qr/^CGI_SESSION=.+/m ), "CGI_SESSION exists";

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION_AGE" ),
	  qr/^SESSION_AGE=0$/m ), "SESSION_AGE=0";

my $start=GET_BODY( "/TestSession__001session_generation?SESSION_START" );
my $time=time;
ok $start=~/^SESSION_START=(\d+)$/ && $time-2<=$1 && $1<=$time,
   "SESSION_START range check";

my $session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp $session;
ok( ($session=~s/^CGI_SESSION=//) &&
    do { sleep 2;
	 t_debug("getting $session/TestSession__001session_generation?SESSION_AGE");
	 my $age=GET_BODY( "$session/TestSession__001session_generation?SESSION_AGE" );
	 ($age=~/^SESSION_AGE=(\d+)/) and 2<=$1 and $1<=3;
       },
    'SESSION_AGE>0' );

ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?EXPIRED_SESSION"),
	  qr/^EXPIRED_SESSION=$/, 'EXPIRED_SESSION not set' );

ok( do { sleep 5;
	 t_debug("getting $session/TestSession__001session_generation?SESSION_AGE");
	 my $age=GET_BODY( "$session/TestSession__001session_generation?SESSION_AGE" );
	 ($age=~/^SESSION_AGE=0$/);
       },
    'MaxSessionAge hit' );

{
  my $s=$session;
  $s=~s/^.*?://;
  ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?EXPIRED_SESSION"),
	    qr/^EXPIRED_SESSION=\Q$s\E$/, 'EXPIRED_SESSION set' );
}

$session=~s/^([^:]+:[^:]+:)(.)(.+)/$1$3$2/;
{
  my $s=$session;
  $s=~s/^.*?://;
  t_client_log_error_is_expected;
  t_start_error_log_watch;
  ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?EXPIRED_SESSION"),
	    qr/^EXPIRED_SESSION=$/, 'invalid session' );
  my @errors=grep {/\[notice\]/} t_finish_error_log_watch();
  ok t_cmp( $errors[0],
	    qr/Caught invalid session: CRC checksum failed/,
	    'check for checksum error message in error_log' );

}

Apache::TestRequest::module('Machine');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

$session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp $session;
ok $session=~s/^CGI_SESSION=// && t_cmp( $session, qr!^/-S:6r56:.+!m ),
   "ClickPathMachine directive at work";

ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?CGI_SESSION" ),
	  qr/^CGI_SESSION=$session/m ), "ClickPathMachine directive at work 2";

Apache::TestRequest::module('NullMachine');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

$session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp $session;
ok $session=~s/^CGI_SESSION=// && t_cmp( $session, qr!^/-S::.+!m ),
   "empty ClickPathMachine directive at work";

ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?CGI_SESSION" ),
	  qr/^CGI_SESSION=$session/m ),
   "empty ClickPathMachine directive at work 2";

Apache::TestRequest::module('Without_UAExc');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=.+/m,  ), "SESSION exists";

mkdir "t/htdocs/tmp2";
open F, ">t/htdocs/tmp2/index.html" and print F <<"EOF";
<html>
<body>
	<p><a href="/klaus/view/index.shtml">link</a></p>
</body>
</html>
EOF
close F;

Apache::TestRequest::module('default');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

$session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp $session;
$session=~s/^CGI_SESSION=//;
ok t_cmp( GET_BODY( "$session/tmp2/" ),
	  qr~<a href="\Q$session\E/klaus/view/index.shtml~,  ),
  "SESSION with sub-request";

Apache::TestRequest::module('Secret');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=.+/m, "Secret SESSION exists" );

ok t_cmp( GET_BODY( "/TestSession__001session_generation?CGI_SESSION" ),
	  qr/^CGI_SESSION=.+/m, "Secret CGI_SESSION exists" );

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION_AGE" ),
	  qr/^SESSION_AGE=0$/m, "Secret SESSION_AGE=0" );

$start=GET_BODY( "/TestSession__001session_generation?SESSION_START" );
$time=time;
ok $start=~/^SESSION_START=(\d+)$/ && $time-2<=$1 && $1<=$time,
   "Secret SESSION_START range check";

$session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp $session;
ok( ($session=~s/^CGI_SESSION=//) &&
    do { sleep 2;
	 t_debug("getting $session/TestSession__001session_generation?SESSION_AGE");
	 my $age=GET_BODY( "$session/TestSession__001session_generation?SESSION_AGE" );
	 t_debug("expected: 2<=AGE<=3");
	 t_debug("received: $age");
	 ($age=~/^SESSION_AGE=(\d+)/) and 2<=$1 and $1<=3;
       },
    'Secret SESSION_AGE>0' );

ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?EXPIRED_SESSION"),
	  qr/^EXPIRED_SESSION=$/, 'Secret EXPIRED_SESSION not set' );

ok( do { sleep 5;
	 t_debug("getting $session/TestSession__001session_generation?SESSION_AGE");
	 my $age=GET_BODY( "$session/TestSession__001session_generation?SESSION_AGE" );
	 t_debug("expected: AGE==0");
	 t_debug("received: $age");
	 ($age=~/^SESSION_AGE=0$/);
       },
    'Secret MaxSessionAge hit' );

{
  my $s=$session;
  $s=~s/^.*?://;
  ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?EXPIRED_SESSION"),
	    qr/^EXPIRED_SESSION=\Q$s\E$/, 'Secret EXPIRED_SESSION set' );
}

$session=~s/^([^:]+:[^:]+:)(.)(.+)/$1$3$2/;
{
  my $s=$session;
  $s=~s/^.*?://;
  t_client_log_error_is_expected;
  t_start_error_log_watch;
  ok t_cmp( GET_BODY( "$session/TestSession__001session_generation?EXPIRED_SESSION"),
	    qr/^EXPIRED_SESSION=$/, 'invalid session (Secret)' );
  my @errors=grep {/\[notice\]/} t_finish_error_log_watch();
  ok t_cmp( $errors[0],
	    qr/Caught invalid session: CRC checksum failed/,
	    'check for checksum error message in error_log (Secret)' );

}

# Local Variables: #
# mode: cperl #
# End: #
