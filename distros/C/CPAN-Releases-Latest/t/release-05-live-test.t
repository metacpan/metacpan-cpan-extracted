#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}


#
# 05-live-test.t
#
# Iterate across all releases and look for the three dists that
# were last released by AMOSS in 1995. Check that we get the expected
# timestamp for each dist.
#

use strict;
use warnings;
use Test::More tests => 2;

use CPAN::Releases::Latest;

my %expected = (
    'Math-Rand48'
        => 'N/NI/NI-S/Math-Rand48-1.00.tar.gz 1999-05-15 09:46:36',

    'Tie-MmapArray'
        => 'A/AN/ANDREWF/Tie-MmapArray-0.04.tar.gz 2000-11-03 07:36:08',

    'Data-Iterator-Hierarchical'
        => 'N/NO/NOBULL/Data-Iterator-Hierarchical-0.07.zip 2008-11-02 14:07:07',
);
my %got;

my $latest;

eval { $latest = CPAN::Releases::Latest->new(max_age => '1 hour') };

SKIP: {
    skip("Looks like either you or MetaCPAN is offline", 2) if $@;

    my $iterator = $latest->release_iterator;

    while (my $release = $iterator->next_release) {
        next unless exists($expected{ $release->distname });
        $got{ $release->distname } = $release->path
                                     .' '
                                     .format_timestamp($release->timestamp);
    }

    ok(keys(%got) == keys(%expected),
       "Did we see the expected number of dists?");

    is(render_dists(\%got), render_dists(\%expected),
       "Did we get the expected information for the dists?");
}

sub format_timestamp
{
    my $timestamp = shift;
    my @tm        = gmtime($timestamp);

    return sprintf('%d-%.2d-%.2d %.2d:%.2d:%.2d',
                   $tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $tm[0]
                  );
}

sub render_dists
{
    my $hashref = shift;
    my $string  = '';

    foreach my $dist (sort { lc($a) cmp lc($b) } keys %$hashref) {
        $string .= "$dist $hashref->{$dist}\n";
    }
    return $string;
}
