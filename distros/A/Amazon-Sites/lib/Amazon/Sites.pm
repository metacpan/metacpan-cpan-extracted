package Amazon::Sites;

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
  say $site->tldr;     # co.uk
  # etc

=head1 DESCRIPTION

A simple class that encapsulates information about Amazon sites.

=cut

use Feature::Compat::Class;

use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.0.5';

class Amazon::Sites {
  use Amazon::Site;

  field %sites = _init_sites();

=head1 METHODS

=head2 new

Creates a new Amazon::Sites object.

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
      $sites{$a}->sort <=> $sites{$b}->sort;
    } keys %sites;

    return \@sites;
  }

  sub _init_sites {
    my %sites;
    my @cols = qw[code country tldn currency sort];

    while (<DATA>) {
      chomp;
      my %site;
      @site{@cols} = split;
      $sites{$site{code}} = Amazon::Site->new(%site);
    }

    return %sites;
  }

=head2 codes

Returns a list of the two-letter country codes, sorted by the sort order.

=cut

  method codes {
    return sort keys %sites;
  } 
}

1;

__DATA__
AE UAE ae AED 1
AU Australia com.au AUD 2
BE Belgium be EUR 3
BR Brazil com.br BRL 4
CA Canada ca CAD 5
CN China cn CNY 6
DE Germany de EUR 7
EG Egypt eg EGP 8
ES Spain es EUR 9
FR France fr EUR 10
IN India in INR 11
IT Italy it EUR 12
JP Japan co.jp JPY 13
MX Mexico com.mx MXN 14
NL Netherlands nl EUR 15
PL Poland pl PLN 16
SA SA sa  SAR 17
SE Sweden se SEK 18
SG Singapore sg SGD 19
TR Turkey com.tr TRY 20
UK UK co.uk GBP 21
US USA com USD 22
