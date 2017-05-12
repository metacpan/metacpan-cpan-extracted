use strict;
use warnings;
use Test::More;
use Test::Deep qw(superhashof cmp_deeply ignore);
use BusyBird::Input::Feed;

if(!$ENV{BB_INPUT_FEED_NETWORK_TEST}) {
    plan('skip_all', "Set BB_INPUT_FEED_NETWORK_TEST environment to enable the test");
    exit;
}

sub sh { superhashof({@_}) }

my $EXP_STATUS = sh(
    id => ignore,
    busybird => sh( status_permalink => ignore ),
    created_at => ignore,
    user => sh( screen_name => ignore )
);

sub check_statuses {
    my ($label, $got_statuses) = @_;
    cmp_ok scalar(@$got_statuses), ">", 0, "$label: loaded at least 1 status";
    foreach my $status (@$got_statuses) {
        cmp_deeply $status, $EXP_STATUS, "$label: status structure OK";
        note("Status: $status->{text}");
    }
}

my $input = BusyBird::Input::Feed->new(use_favicon => 0);

check_statuses "parse_url, atom", $input->parse_url("http://www.perl.com/pub/atom.xml");
check_statuses "parse_uri, rdf, https", $input->parse_uri('https://metacpan.org/feed/recent');

done_testing;

