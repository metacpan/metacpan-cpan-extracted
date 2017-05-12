#
#===============================================================================
#
#         FILE:  02subwizard.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (davinchi), <boldin.pavel@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  12.10.2007 01:08:33 SAMST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 11;                      # last test to print

use lib qw(t/lib t/mechanize/lib t/mechanize/lib/WizardTest);
use ok 'Test::WWW::Mechanize::Catalyst' => 'WizardTestApp';
use Test::Wizard;

$m = Test::WWW::Mechanize::Catalyst->new(requests_redirectable => []);

ok_redirect('http://localhost/first/first_step?testsub=1', '/first/second_step', 'first step');

# to the new wizard
my $old_wid = $wid;

undef $wid;
ok_redirect(undef, '/second/preved_step', 'second step');

# to the old wizard
$wid = $old_wid;
ok_redirect(undef, '/first/second_step', 
    'second preved step - come back to first/second_step');

ok_redirect(undef, '/first/first_step', 'to first_step');

ok_redirect(undef, undef, 'ok, get first_step');

$m->content_like(qr/Thats ok!/, 'wizard test passed');
