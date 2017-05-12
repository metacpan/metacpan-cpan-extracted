#!/usr/bin/perl

# Test _rest_devpopup
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::LongString max => 5000;
use Test::More tests => 2;
use Test::WWW::Mechanize::CGIApp;
use lib 't/lib';
use Test::CAPRESTPopup;
use Test::CAPRESTNoPopup;

my $mech1 = Test::WWW::Mechanize::CGIApp->new;

$mech1->add_header(Accept => '*/*;q=1.0');
$mech1->app(
    sub {
        my $app = Test::CAPRESTPopup->new;
        $app->run();
    }
);

my $expected1 = <<'EOT';
<table>\n" + 
	"<tr><td>method: </td><td colspan=\"2\">GET</td></tr>\n" + 
	"<tr><td>mimetype: </td><td colspan=\"2\">*/*</td></tr>\n" + 
	"<tr><td>path received: </td><td colspan=\"2\">/foo/alpha/beta/gamma/</td></tr>\n" + 
	"<tr><td>rule matched: </td><td colspan=\"2\">/foo/:one/:two/:three/</td></tr>\n" + 
	"<tr><td>runmode: </td><td colspan=\"2\">doop</td></tr>\n" + 
	"<tr><td rowspan=\"3\">parameters: </td><td>one: </td><td>alpha</td></tr>\n" + 
	"<tr><td>three: </td><td>gamma</td></tr>\n" + 
	"<tr><td>two: </td><td>beta</td></tr>\n" + 
	"</table>\n" + 
EOT

$mech1->get('http://localhost/foo/alpha/beta/gamma/');
contains_string($mech1->content, $expected1, 'devpopup');

my $mech2 = Test::WWW::Mechanize::CGIApp->new;

$mech2->add_header(Accept => '*/*;q=1.0');
$mech2->app(
    sub {
        my $app = Test::CAPRESTNoPopup->new;
        $app->run();
    }
);

my $expected2 = qq{<body>

</body>
};


$mech2->get('http://localhost/bar');
contains_string($mech2->content, $expected2, 'without devpopup');
