use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 49;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

mkdir "t/htdocs/tmp";
open F, ">t/htdocs/tmp/x.html" and print F <<"EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>output_body</title>
    <meta http-equiv="refresh" content="10; URL=/index1.html">
    <meta http-equiv=refresh content=10;URL=/index2.html>
    <meta content="10; URL=/index3.html" http-equiv="refresh">
    <meta content="10; URL=http://$hostport/index4.html" http-equiv="refresh">
    <meta content="10; URL=../index5.html" http-equiv="refresh">
    <meta content="10; URL=http://x.y/index5.html" http-equiv="refresh">
    <meta content="10; URL=http://$hostport/-S:s9NNNd:d3\@zidNNZkcH79NNNNNM/index7.html" http-equiv="refresh">
  </head>

  <body>
    <a href="/index1.html">1</a>
    <a href="http://$hostport/index1.html">2</a>
    <a href="javascript:window.close();">javascript</a>
    <a href="mailto:bla">mailto</a>
    <a href="#top">hash</a>
    <a href="../index1.html">3</a>
    <a href="http://x.y/index1.html">4</a>
    <area href="/index1.html">1</area>
    <area href="http://$hostport/index1.html">2</area>
    <AREA title='klaus' href="../index1.html" coords="1,2,3,4,5">3</AREA>
    <area title="klaus" href="http://x.y/index1.html" coords='1,2,3,4,5'>4</area>
    <form action="/index1.html">1</form>
    <form action="http://$hostport/index1.html">2</form>
    <form action="../index1.html">3</form>
    <form action="http://x.y/index1.html">4</form>
    <frame src="/index1.html">1</frame>
    <FRAME blub="bla" SRC="http://$hostport/index1.html">2</frame>
    <frame src="../index1.html">3</frame>
    <frame src="http://x.y/index1.html">4</frame>
    <iframe src="/index1.html">1</iframe>
    <iframe src="http://$hostport/index1.html">2</iframe>
    <iframe src="../index1.html">3</iframe>
    <iframe src="http://x.y/index1.html">4</iframe>
  </body>
</html>
EOF
close F;

open F, ">t/htdocs/tmp/y.html" and print F <<"EOF";

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
	<head>
		<meta http-equiv="content-type" content="text/html;charset=ISO-8859-1">
		<meta HTTP-EQUIV=REFRESH CONTENT="0; URL=/klaus/view/index.shtml">
	</head>

	<body>
		<center>
			<div class="box">
				<span class="headline">Weiterleitung&nbsp;|&nbsp;</span>eine&nbsp;Moment&nbsp;bitte
			</div>
			<p>Sie werden automatisch auf die gew&uuml;nschte Seite weitergeleitet.<p>
			<p><a href="/klaus/view/index.shtml">Falls Ihr Browser keine Weiterleitung unterst&uuml;tzt, klicken Sie bitte hier.</a></p>
		</center>
	</body>

</html>
EOF
close F;

my $got=GET_BODY( "/tmp/x.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!<meta http-equiv="refresh" content="10; URL=/-S:\S+/index1\.html">! ),
    "meta 1" );
ok( t_cmp( $got, qr!<meta http-equiv=refresh content=10;URL=/index2\.html>! ),
    "meta 2" );
ok( t_cmp( $got, qr!<meta content="10; URL=/-S:\S+/index3\.html" http-equiv="refresh">! ),
    "meta 3" );
ok( t_cmp( $got, qr!<meta content="10; URL=http://\Q$hostport\E/-S:\S+/index4\.html" http-equiv="refresh">! ),
    "meta 4" );
ok( t_cmp( $got, qr!<meta content="10; URL=/-S:\S+/tmp/\.\./index5\.html" http-equiv="refresh">! ),
    "meta 5" );
ok( t_cmp( $got, qr!<meta content="10; URL=http://x\.y/index5\.html" http-equiv="refresh">! ),
    "meta 6" );
ok( t_cmp( $got, qr!<meta content="10; URL=http://\Q$hostport\E/-S:\S+/index7\.html" http-equiv="refresh">! ),
    "meta 7" );

ok( t_cmp( $got, qr!<a href="/-S:\S+/index1\.html">1</a>! ),
    "a 1" );
ok( t_cmp( $got, qr!<a href="http://\Q$hostport\E/-S:\S+/index1\.html">2</a>! ),
    "a 2" );
ok( t_cmp( $got, qr!<a href="/-S:\S+/tmp/\.\./index1\.html">3</a>! ),
    "a 3" );
ok( t_cmp( $got, qr!<a href="http://x\.y/index1\.html">4</a>! ),
    "a 4" );
ok( t_cmp( $got, qr!<a href="javascript:window\.close\(\);">javascript</a>! ),
    "javascript" );
ok( t_cmp( $got, qr!<a href="mailto:bla">mailto</a>! ),
    "mailto" );
ok( t_cmp( $got, qr!<a href="#top">hash</a>! ),
    "hash" );

ok( t_cmp( $got, qr!<area href="/-S:\S+/index1\.html">1</area>! ),
    "area 1" );
ok( t_cmp( $got, qr!<area href="http://\Q$hostport\E/-S:\S+/index1\.html">2</area>! ),
    "area 2" );
ok( t_cmp( $got, qr!<AREA title='klaus' href="/-S:\S+/tmp/\.\./index1\.html" coords="1,2,3,4,5">3</AREA>! ),
    "area 3" );
ok( t_cmp( $got, qr!<area title="klaus" href="http://x\.y/index1\.html" coords='1,2,3,4,5'>4</area>! ),
    "area 4" );

ok( t_cmp( $got, qr!<form action="/-S:\S+/index1\.html">1</form>! ),
    "form 1" );
ok( t_cmp( $got, qr!<form action="http://\Q$hostport\E/-S:\S+/index1\.html">2</form>! ),
    "form 2" );
ok( t_cmp( $got, qr!<form action="/-S:\S+/tmp/\.\./index1\.html">3</form>! ),
    "form 3" );
ok( t_cmp( $got, qr!<form action="http://x.y/index1.html">4</form>! ),
    "form 4" );

my $session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
chomp $session;
$session=~s/^.*?=//;

$got=GET_BODY( "$session/tmp/x.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!<meta http-equiv="refresh" content="10; URL=\Q$session\E/index1\.html">! ),
    "meta 1" );
ok( t_cmp( $got, qr!<meta http-equiv=refresh content=10;URL=/index2\.html>! ),
    "meta 2" );
ok( t_cmp( $got, qr!<meta content="10; URL=\Q$session\E/index3\.html" http-equiv="refresh">! ),
    "meta 3" );
ok( t_cmp( $got, qr!<meta content="10; URL=http://\Q$hostport$session\E/index4\.html" http-equiv="refresh">! ),
    "meta 4" );
ok( t_cmp( $got, qr!<meta content="10; URL=\.\./index5\.html" http-equiv="refresh">! ),
    "meta 5" );
ok( t_cmp( $got, qr!<meta content="10; URL=http://x\.y/index5\.html" http-equiv="refresh">! ),
    "meta 6" );

ok( t_cmp( $got, qr!<a href="\Q$session\E/index1\.html">1</a>! ),
    "a 1" );
ok( t_cmp( $got, qr!<a href="http://\Q$hostport$session\E/index1\.html">2</a>! ),
    "a 2" );
ok( t_cmp( $got, qr!<a href="\.\./index1\.html">3</a>! ),
    "a 3" );
ok( t_cmp( $got, qr!<a href="http://x\.y/index1\.html">4</a>! ),
    "a 4" );
ok( t_cmp( $got, qr!<a href="javascript:window\.close\(\);">javascript</a>! ),
    "javascript" );
ok( t_cmp( $got, qr!<a href="mailto:bla">mailto</a>! ),
    "mailto" );
ok( t_cmp( $got, qr!<a href="#top">hash</a>! ),
    "hash" );

ok( t_cmp( $got, qr!<form action="\Q$session\E/index1\.html">1</form>! ),
    "form 1" );
ok( t_cmp( $got, qr!<form action="http://\Q$hostport$session\E/index1\.html">2</form>! ),
    "form 2" );
ok( t_cmp( $got, qr!<form action="\.\./index1\.html">3</form>! ),
    "form 3" );
ok( t_cmp( $got, qr!<form action="http://x.y/index1.html">4</form>! ),
    "form 4" );

ok( t_cmp( $got, qr!<frame src="\Q$session\E/index1\.html">1</frame>! ),
    "frame 1" );
ok( t_cmp( $got, qr!<FRAME blub="bla" SRC="http://\Q$hostport$session\E/index1\.html">2</frame>! ),
    "frame 2" );
ok( t_cmp( $got, qr!<frame src="\.\./index1\.html">3</frame>! ),
    "frame 3" );
ok( t_cmp( $got, qr!<frame src="http://x.y/index1.html">4</frame>! ),
    "frame 4" );

ok( t_cmp( $got, qr!<iframe src="\Q$session\E/index1\.html">1</iframe>! ),
    "iframe 1" );
ok( t_cmp( $got, qr!<iframe src="http://\Q$hostport$session\E/index1\.html">2</iframe>! ),
    "iframe 2" );
ok( t_cmp( $got, qr!<iframe src="\.\./index1\.html">3</iframe>! ),
    "iframe 3" );
ok( t_cmp( $got, qr!<iframe src="http://x.y/index1.html">4</iframe>! ),
    "iframe 4" );

$got=GET_BODY( "$session/tmp/y.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!<meta HTTP-EQUIV=REFRESH CONTENT="0; URL=\Q$session\E/klaus/view/index\.shtml">! ),
    "y.html - <meta>" );
ok( t_cmp( $got, qr!<a href="\Q$session\E/klaus/view/index\.shtml">! ),
    "y.html - <a>" );

# Local Variables: #
# mode: cperl #
# End: #
