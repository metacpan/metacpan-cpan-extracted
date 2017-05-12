use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw'GET_BODY GET_HEAD';

plan tests => 27;

Apache::TestRequest::module('FriendlySession');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

my $cgisession=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp( $cgisession );
$cgisession=~s/^CGI_SESSION=//;

my $normal_cgisession_len=length( $cgisession );

my $got=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
		  referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8a#b/9&c=;d;ld=25&x=33' );
chomp( $got );
$got=~s/^CGI_SESSION=//;

t_debug( "CGI_SESSION=$got" );

ok t_cmp( $got, qr%^/-S:[^/#]+$%, 'no / nor #' );

t_debug( "testing: session string length (param)" );
t_debug( "expected: more than ".$normal_cgisession_len );
t_debug( "received: ".length($got) );
ok length($got)>$normal_cgisession_len, 'session string length (param)';

$got=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
	       referer=>'https://uri.friendly.org/mach/blah/sess/cgi-bin/blah.pl' );
chomp( $got );
$got=~s/^CGI_SESSION=//;

t_debug( "testing: session string length (uri)" );
t_debug( "expected: more than ".$normal_cgisession_len );
t_debug( "received: ".length($got) );
ok length($got)>$normal_cgisession_len, 'session string length (uri)';

$got=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
	       referer=>'https://mixed.friendly.org/mach/blah/sess/cgi-bin/blah.pl?a=b;ld=2;x' );
chomp( $got );
$got=~s/^CGI_SESSION=//;

t_debug( "testing: session string length (mixed)" );
t_debug( "expected: more than ".$normal_cgisession_len );
t_debug( "received: ".length($got) );
ok length($got)>$normal_cgisession_len, 'session string length (mixed)';

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION' );
REMOTE_SESSION=ld=25
id=8ab9
EOT

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b&ld=21;id=8fd9&c=;d;&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION reverse order' );
REMOTE_SESSION=ld=21
id=8fd9
EOT

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION_HOST",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b&ld=21;id=8fd9&c=;d;&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION_HOST' );
REMOTE_SESSION_HOST=param.friendly.org
EOT

$cgisession=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
		      referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8a/b#9&c=;d;ld=25&x=33' );
chomp( $cgisession );
$cgisession=~s/^CGI_SESSION=//;

$got=GET_BODY( "$cgisession/TestSession__001session_generation?REMOTE_SESSION" );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION with session part' );
REMOTE_SESSION=ld=25
id=8a/b#9
EOT

$got=GET_BODY( "$cgisession/TestSession__001session_generation?REMOTE_SESSION_HOST" );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION_HOST with session part' );
REMOTE_SESSION_HOST=param.friendly.org
EOT

sleep 3;

$got=GET_BODY( "$cgisession/TestSession__001session_generation?REMOTE_SESSION" );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION timeout' );
REMOTE_SESSION=
EOT

$got=GET_BODY( "$cgisession/TestSession__001session_generation?REMOTE_SESSION_HOST" );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION_HOST timeout' );
REMOTE_SESSION_HOST=
EOT

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://uri.friendly.org/mach/blah/sess/cgi-bin/blah.pl' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION (uri)' );
REMOTE_SESSION=mach
sess
EOT

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://mixed.friendly.org/mach/blah/sess/cgi-bin/blah.pl?a=b;ld=2;x' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION (mixed)' );
REMOTE_SESSION=ld=2
sess
EOT

my $exc="$config->{vars}->{serverroot}/FriendlySessions";

t_debug( "Unlinking $exc" );
unlink $exc if( -e $exc );
die "Cannot remove $exc: $!\n" if( -e $exc );
t_debug( "Creating $exc" );
open my $f, ">$exc" or die "Cannot open $exc: $!\n";
select( (select($f), $|=1)[0] );

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION must now be empty' );
REMOTE_SESSION=
EOT

my $tread=GET_BODY( "/TestSession__007uaexceptionfile?FriendlySessions",
		    referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $tread, qr/^\d+$/, 'ClickPathFriendlySessionsFile reading time' );

sleep 2;
my $t=GET_BODY( "/TestSession__007uaexceptionfile?FriendlySessions",
		referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $t, $tread, 'ClickPathFriendlySessionsFile Cache' );

print $f "  param.friendly.org   param(id) param ( ld )   f\n";

t_debug( "testing: reread ClickPathFriendlySessionsFile" );
t_debug( "expected: more than $tread" );
$t=GET_BODY( "/TestSession__007uaexceptionfile?FriendlySessions",
	     referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
t_debug( "received: $t" );
ok $t>$tread, 'reread ClickPathFriendlySessionsFile';

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION not empty again' );
REMOTE_SESSION=id=8ab9
ld=25
EOT

t_debug( "Unlinking $exc" );
unlink $exc;

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION original state again' );
REMOTE_SESSION=ld=25
id=8ab9
EOT

Apache::TestRequest::module('Secret');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

$cgisession=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp( $cgisession );
$cgisession=~s/^CGI_SESSION=//;

$normal_cgisession_len=length( $cgisession );

$got=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
		  referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8a#b/9&c=;d;ld=25&x=33' );
chomp( $got );
$got=~s/^CGI_SESSION=//;

t_debug( "CGI_SESSION=$got" );

ok t_cmp( $got, qr%^/-S:[^/#]+$%, 'no / nor # (Secret)' );

t_debug( "testing: session string length (param) (Secret)" );
t_debug( "expected: more than ".$normal_cgisession_len );
t_debug( "received: ".length($got) );
ok length($got)>$normal_cgisession_len, 'session string length (param) (Secret)';

$got=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
	       referer=>'https://uri.friendly.org/mach/blah/sess/cgi-bin/blah.pl' );
chomp( $got );
$got=~s/^CGI_SESSION=//;

t_debug( "testing: session string length (uri) (Secret)" );
t_debug( "expected: more than ".$normal_cgisession_len );
t_debug( "received: ".length($got) );
ok length($got)>$normal_cgisession_len, 'session string length (uri) (Secret)';

$got=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
	       referer=>'https://mixed.friendly.org/mach/blah/sess/cgi-bin/blah.pl?a=b;ld=2;x' );
chomp( $got );
$got=~s/^CGI_SESSION=//;

t_debug( "testing: session string length (mixed) (Secret)" );
t_debug( "expected: more than ".$normal_cgisession_len );
t_debug( "received: ".length($got) );
ok length($got)>$normal_cgisession_len, 'session string length (mixed) (Secret)';

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8ab9&c=;d;ld=25&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION (Secret)' );
REMOTE_SESSION=ld=25
id=8ab9
EOT

$got=GET_BODY( "/TestSession__001session_generation?REMOTE_SESSION_HOST",
	       referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b&ld=21;id=8fd9&c=;d;&x=33' );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION_HOST (Secret)' );
REMOTE_SESSION_HOST=param.friendly.org
EOT

$cgisession=GET_BODY( "/TestSession__001session_generation?CGI_SESSION",
		      referer=>'https://param.friendly.org/cgi-bin/blah.pl?a=b;id=8a/b#9&c=;d;ld=25&x=33' );
chomp( $cgisession );
$cgisession=~s/^CGI_SESSION=//;
t_debug( "Using session: $cgisession" );

$got=GET_BODY( "$cgisession/TestSession__001session_generation?REMOTE_SESSION" );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION with session part (Secret)' );
REMOTE_SESSION=ld=25
id=8a/b#9
EOT

$got=GET_BODY( "$cgisession/TestSession__001session_generation?REMOTE_SESSION_HOST" );
ok t_cmp( $got, <<'EOT', 'REMOTE_SESSION_HOST with session part (Secret)' );
REMOTE_SESSION_HOST=param.friendly.org
EOT

# Local Variables: #
# mode: cperl #
# End: #
