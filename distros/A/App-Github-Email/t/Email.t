use Test::More tests => 7;

use_ok('LWP::UserAgent');
use_ok('Getopt::Long::Descriptive');
use_ok('JSON');
use_ok( 'List::MoreUtils', qw(uniq) );
use_ok( 'LWP::Online',     qw(online) );
use_ok('App::Github::Email');

sub get_user {
    my @addresses = App::Github::Email::get_user('faraco');

    for my $address (@addresses) {
        return 1 if $address eq 'skelic3@gmail.com';
    }
}

SKIP:
{
    skip "No internet connection", 1 unless online();

    ok( get_user, "Getting faraco's github account email working fine." );
}

done_testing;
