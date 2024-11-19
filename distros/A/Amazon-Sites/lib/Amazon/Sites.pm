=head1 NAME

Amazon::Sites - A class to represent Amazon sites

=head1 SYNOPSIS

  use Amazon::Sites;

  my $sites = Amazon::Sites->new;
  my @sites = $sites->sites;
  my %sites = $sites->sites_hash;
  my @codes = $sites->codes;

  my $site  = $sites->site('UK');
  say $site->currency; # GBP
  say $site->tldn;     # co.uk
  # etc

  my %urls = $sites->asin_urls('XXXXXXX');
  say $urls{UK}; # https://amazon.co.uk/dp/XXXXXXX
  # etc

=head1 DESCRIPTION

A simple class that encapsulates information about Amazon sites.

=cut

use strict;
use warnings;

use Feature::Compat::Class;

use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.1.9';

class Amazon::Sites;

use Amazon::Site ();

field $include :param = [];
field $exclude :param = [];
field $assoc_codes :param = {};
field %sites = _init_sites($assoc_codes, $include, $exclude);

ADJUST {
  if (@$include and @$exclude) {
    die "You can't specify both include and exclude";
  }
}

=head1 METHODS

=head2 new

Creates a new Amazon::Sites object.

    my $sites = Amazon::Sites->new;

You can also specify a list of sites to include or exclude:

    # Only include the US site
    my $sites = Amazon::Sites->new(include => [ 'US' ]);
    # Exclude the US site
    my $sites = Amazon::Sites->new(exclude => [ 'US' ]);

At most one of `include` or `exclude` can be specified.

You can also specify a hash of associate codes:

    my $sites = Amazon::Sites->new(assoc_codes => {
      UK => 'My Associate Code',
    });

=head2 sites_hash

Returns a hash where the keys are the two-letter country codes and the values are
L<Amazon::Site> objects.

=cut

method sites_hash { return %sites }

=head2 site($code)

Given a two-letter country code, returns the corresponding L<Amazon::Site> object.

=cut

method site ($code) { return $sites{$code} }

=head2 sites

Returns a list of L<Amazon::Site> objects, sorted by the sort order.

=cut

method sites {
  my @sites = sort {
    $a->sort <=> $b->sort;
  } values %sites;

  return @sites;
}

sub _init_sites($assoc_codes, $include, $exclude) {
  my %sites;
  my @cols = qw[code country tldn currency sort];

  my $where = tell DATA;

  while (<DATA>) {
    chomp;
    my %site;
    @site{@cols} = split /\t/;

    next if @$include and not grep { $site{code} eq $_ } @$include;
    next if @$exclude and grep { $site{code} eq $_ } @$exclude;

    $site{assoc_code} = $assoc_codes->{$site{code}} if $assoc_codes->{$site{code}};

    $sites{$site{code}} = Amazon::Site->new(%site);
  }

  seek DATA, $where, 0;

  return %sites;
}

=head2 codes

Returns a list of the two-letter country codes, sorted by the sort order.

=cut

method codes {
  return sort keys %sites;
}

=head2 asin_urls

Given an ASIN, returns a hash where the keys are the two-letter country
codes and the values are the corresponding ASIN URLs.

=cut

method asin_urls ($asin) {
  my %urls;
  for my $site ($self->sites) {
    $urls{$site->code} = $site->asin_url($asin);
  }

  return %urls;
}

1;

=head1 COPYRIGHT

Copyright 2024, Dave Cross. All rights reserved.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item * the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version, or

=item * the Artistic License version 2.0.

=back

=cut

__DATA__
AE	UAE	ae	AED	1
AU	Australia	com.au	AUD	2
BE	Belgium	com.be	EUR	3
BR	Brazil	com.br	BRL	4
CA	Canada	ca	CAD	5
CN	China	cn	CNY	6
DE	Germany	de	EUR	7
EG	Egypt	eg	EGP	8
ES	Spain	es	EUR	9
FR	France	fr	EUR	10
IN	India	in	INR	11
IT	Italy	it	EUR	12
JP	Japan	co.jp	JPY	13
MX	Mexico	com.mx	MXN	14
NL	Netherlands	nl	EUR	15
PL	Poland	pl	PLN	16
SA	Saudi Arabia	sa	SAR	17
SE	Sweden	se	SEK	18
SG	Singapore	sg	SGD	19
TR	Turkey	com.tr	TRY	20
UK	United Kingdom	co.uk	GBP	21
US	USA	com	USD	22
