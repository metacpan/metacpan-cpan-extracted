#
#===============================================================================
# #         FILE:  05wizard_complex.t
#
#  DESCRIPTION:  Complex wizard test
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (davinchi), <boldin.pavel@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  30.10.2007 23:45:48 SAMT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 39;                      # last test to print

use lib qw(t/lib t/mechanize/lib t/mechanize/lib/WizardTest);
use ok 'Test::WWW::Mechanize::Catalyst' => 'ComplexWizardTestApp';
use Test::Wizard;

$m = Test::WWW::Mechanize::Catalyst->new(requests_redirectable => []);
undef $wid;

ok_redirect('http://localhost/first/edit', '/first/login', 'try edit');

ok_redirect(undef, undef, 'to login');

$m->title_is('Test login');

$m->submit_form(
    form_name   => 'login',
    fields      => {
        username => 'userfailed',
        password => 'userpassword'
    }
);


$m->content_contains('Incorrect login', 'Incorrect login ok');
$m->title_is('Test login');

$m->submit_form(
    form_name   => 'login',
    fields      => {
        username => 'user',
        password => 'userpassword'
    }
);

$m->content_contains('login ok', 'logged in ok');

ok_redirect('/first/edit/ready_for_fun', undef, 'getting ready for fun');

# new wizard
undef $wid;

my $content = $m->content;
my @hops = ($content =~ /h(\d+),?/go);

$next_url = '/first/fun/'.shift(@hops);

push @hops, 'last';

while (@hops) {
    # HIP HOP!
    my $redir = "/first/fun/".shift(@hops);
    ok_redirect(undef, $redir, "hopgins: /first/fun -> $redir");
}

ok_redirect(undef, '/first/eatme', "/first/fun/last -> /first/eatme");

#SKIP: {
    #skip "back steps not supported yet", 2;
    ok_redirect(undef, '/first/fun/last', 
		"back 2 steps to /first/fun/10", 'back', 2);

    ok_redirect(undef, '/first/eatme', 
		"forward to /first/fun/last -> redirects to /first/eatme");

#}

ok_redirect(undef, '/first/drinkme', "/first/drinkme");

$m->get($next_url);

$m->content_contains('eated and drinked, thanks', 'eated and drinked - ok');

$m->follow_link( url_regex => qr/test\/followme/i );

$m->content_contains('all ok!', 'all you base belong to us');
