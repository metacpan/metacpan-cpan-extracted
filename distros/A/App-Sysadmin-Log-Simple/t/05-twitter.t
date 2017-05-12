use strict;
use warnings;
use Test::More tests => 2;
use App::Sysadmin::Log::Simple::Twitter;

my $log = new_ok('App::Sysadmin::Log::Simple::Twitter', [
    app => { do_twitter => 1 },
]);

SKIP: {
    skip 'author testing', 1 unless defined $ENV{TEST_TWITTER};
    my $logentry = rand;
    my $return = $log->log($logentry);
    if (like($return, qr{Posted to Twitter}, 'Twitter plugin reports success')) {
        diag $return;
    }
    else {
        diag explain $return;
    }
}
