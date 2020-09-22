#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print qq{1..0 # SKIP these tests only run with AUTHOR_TESTING set\n};
        exit
    }
}

use strict;
use warnings 'all';

use lib 't/lib';

use BZ::Client::Test();
use BZ::Client::Bug();
use Test::More;

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
# use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';

plan tests => ( scalar @bugzillas * 1 );

my $tester;

my %quirks = (
    '5.1' => { supported => 1 },
    '4.4' => { supported => 1 },
    '4.2' => { supported => 0 },
);

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {

        skip( 'No Bugzilla server configured, skipping', 1 )
          if $tester->isSkippingIntegrationTests();

        skip( 'This Bugzilla does not support the Group API', 1)
          unless ($server->{version} and
           $quirks{ $server->{version} }->{supported});

        ok(1,'NO Useful Tests not yet written');

    }

}
