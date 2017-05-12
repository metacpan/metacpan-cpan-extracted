use 5.008001;
use strict;
use warnings;

package Data::Fake::Internet;
# ABSTRACT: Fake Internet-related data generators

our $VERSION = '0.003';

use Exporter 5.57 qw/import/;

our @EXPORT = qw(
  fake_tld
  fake_domain
  fake_email
);

use Data::Fake::Text  ();
use Data::Fake::Names ();

my ( @domain_suffixes, $domain_suffix_count );

sub _domain_suffix { return $domain_suffixes[ int( rand($domain_suffix_count) ) ] }

#pod =func fake_tld
#pod
#pod     $generator = fake_tld();
#pod
#pod Returns a generator that randomly selects from a weighted list of about 50
#pod domain suffixes based on a list of the top 500 domains by inbound
#pod root-domain links.
#pod
#pod =cut

sub fake_tld {
    return sub { _domain_suffix };
}

#pod =func fake_domain
#pod
#pod     $generator = fake_domain();
#pod
#pod Returns a generator that concatenates two random words with a random
#pod domain suffix.
#pod
#pod =cut

sub fake_domain {
    my $prefix_gen = Data::Fake::Text::fake_words(2);
    return sub {
        my $prefix = $prefix_gen->();
        $prefix =~ s/\s//g;
        join( ".", $prefix, _domain_suffix );
    };
}

#pod =func fake_email
#pod
#pod     $generator = fake_email();
#pod
#pod Returns a generator that constructs an email from a random name and a
#pod random domain.
#pod
#pod =cut

sub fake_email {
    my $fn = Data::Fake::Names::fake_first_name;
    my $ln = Data::Fake::Names::fake_surname;
    my $dn = fake_domain;
    return sub {
        return sprintf( "%s.%s@%s", map { lc } map { $_->() } $fn, $ln, $dn );
    };
}

# list and frequencey of most common domains suffixes taken from moz.org
# list of top 500 domains by inbound root domain links

my @domain_suffix_freqs = qw(
  com     295
  org     29
  edu     27
  gov     25
  net     15
  co.uk   12
  ru      9
  jp      7
  ne.jp   7
  de      6
  co.jp   5
  fr      4
  gov.au  3
  io      3
  com.cn  3
  it      3
  cn      3
  cz      3
  gov.cn  2
  me      2
  ca      2
  com.br  2
  co      2
  us      2
  com.au  2
  pl      2
  uk      2
  ac.uk   2
  info    1
  gl      1
  tx.us   1
  la      1
  com.hk  1
  gd      1
  vu      1
  eu      1
  es      1
  int     1
  tv      1
  or.jp   1
  mil     1
  cc      1
  ch      1
  ly      1
  org.au  1
  net.au  1
  fm      1
  be      1
  nl      1
);

for my $i ( 0 .. @domain_suffix_freqs / 2 - 1 ) {
    my ( $s, $n ) =
      ( $domain_suffix_freqs[ 2 * $i ], $domain_suffix_freqs[ 2 * $i + 1 ] );
    push @domain_suffixes, ($s) x $n;
}

$domain_suffix_count = @domain_suffixes;

1;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::Internet - Fake Internet-related data generators

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Data::Fake::Internet;

    fake_tld()->();     # .gov, etc.
    fake_domain()->();  # atqueaut.gov, etc.
    fake_email()->();   # john.smith@atqueaut.gov, etc.

=head1 DESCRIPTION

This module provides fake data generators for Internet-related data.

All functions are exported by default.

=head1 FUNCTIONS

=head2 fake_tld

    $generator = fake_tld();

Returns a generator that randomly selects from a weighted list of about 50
domain suffixes based on a list of the top 500 domains by inbound
root-domain links.

=head2 fake_domain

    $generator = fake_domain();

Returns a generator that concatenates two random words with a random
domain suffix.

=head2 fake_email

    $generator = fake_email();

Returns a generator that constructs an email from a random name and a
random domain.

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
