#!/usr/bin/env perl

# Display the disc information for any mounted CDs on an OS X system.

use warnings;
use strict;
use lib qw(./lib);

use Mac::PropertyList qw(parse_plist_file);
use CDDB;

my $cddb = CDDB->new();

CD: foreach my $toc_name (</Volumes/*/.TOC.plist>) {
  my $toc = parse_plist_file($toc_name);

  my @toc;

  foreach my $track (@{$toc->{'Sessions'}[0]{'Track Array'}}) {
    my $number = $track->{'Point'}->value();
    my $block  = $track->{'Start Block'}->value();
    push @toc, "$number 0 0 $block";
  }

  push @toc, '999 0 0 ' . $toc->{'Sessions'}[0]{'Leadout Block'}->value();

  my @discs = $cddb->get_discs_by_toc(@toc);
  unless (@discs) {
    warn "$toc_name = no discs found";
    next CD;
  }

  foreach my $disc (@discs) {
    my ($genre, $id, $title) = @$disc;

    my $disc_details = $cddb->get_disc_details($genre, $id);

    delete $disc_details->{xmcd_record}; # for display
    use YAML::Syck; print YAML::Syck::Dump($disc_details);
  }
}
