use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw'GET_BODY GET_HEAD';

plan tests => 9;

Apache::TestRequest::user_agent
  (reset => 1, agent=>'Googlebot/2.1 (+http://www.google.com/bot.html)');

Apache::TestRequest::module('UAExceptionsFile');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

my $exc="$config->{vars}->{serverroot}/UAExceptions";

t_debug( "Unlinking $exc" );
unlink $exc if( -e $exc );
die "Cannot remove $exc: $!\n" if( -e $exc );
ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=Google$/m, "SESSION is Google" );

t_debug( "Creating $exc" );
open my $f, ">$exc" or die "Cannot open $exc: $!\n";
select( (select($f), $|=1)[0] );
ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=(?!Google).+$/m, "SESSION is not Google anymore" );

my $tread=GET_BODY( "/TestSession__007uaexceptionfile" );
ok t_cmp( $tread, qr/^\d+$/, 'ClickPathUAExceptionsFile reading time' );

sleep 2;
my $t=GET_BODY( "/TestSession__007uaexceptionfile" );
ok t_cmp( $t, $tread, 'ClickPathUAExceptionsFile Cache' );

print $f "klaus ^otto\n";

t_debug( "testing: reread ClickPathUAExceptionsFile" );
t_debug( "expected: more than $tread" );
$t=GET_BODY( "/TestSession__007uaexceptionfile" );
t_debug( "received: $t" );
ok $t>$tread, 'reread ClickPathUAExceptionsFile';

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=(?!Google).+$/m, "still getting a SESSION" );

Apache::TestRequest::user_agent (reset => 1, agent=>'klaus otto');

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=(?!Google).+$/m, "still getting a SESSION 2" );

Apache::TestRequest::user_agent (reset => 1, agent=>'otto klaus');

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=klaus$/m, "SESSION is klaus" );

Apache::TestRequest::user_agent
  (reset => 1, agent=>'Googlebot/2.1 (+http://www.google.com/bot.html)');

t_debug( "Unlinking $exc" );
unlink $exc;

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=Google$/m, "SESSION is Google again" );

# Local Variables: #
# mode: cperl #
# End: #
