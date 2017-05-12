#
#===============================================================================
#
#         FILE:  06wizard_catalyst.t
#
#  DESCRIPTION:  Testing catalyst $c->detach_next_action and etc.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (davinchi), <boldin.pavel@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04.11.2007 16:35:06 SAMT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 7;                      # last test to print
use lib qw(t/lib t/mechanize/lib t/mechanize/lib/WizardTest);
use ok 'Test::WWW::Mechanize::Catalyst' => 'ComplexWizardTestApp';
use Test::Wizard;

$m = Test::WWW::Mechanize::Catalyst->new(requests_redirectable => []);

ok_redirect('http://localhost/second/def', '/second/def_second', 'ok redirecting to default');

undef $wid;
ok_redirect(undef, '/second/def/2', 'ok default redirect');

ok_redirect(undef, undef, 'ok getting page was redirected to');

$m->content_is('OK!', 'passed test ok');
