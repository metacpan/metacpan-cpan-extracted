#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use_ok "Acme::Free::API::ChuckNorris";

note "### A quote from each category, for your entertainment:";
my $cnq = Acme::Free::API::ChuckNorris->new;
my $cats = $cnq->categories;
foreach my $cat ( $cats->all ) {
  note sprintf("%s\n", $cnq->random( category => $cat ));
}

__END__
