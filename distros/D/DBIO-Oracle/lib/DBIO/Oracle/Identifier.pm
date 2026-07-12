package DBIO::Oracle::Identifier;
# ABSTRACT: Shorten Oracle identifiers to the 30-character limit

use strict;
use warnings;

use Digest::MD5 ();
use Math::BigInt ();
use Math::Base36 ();



sub shorten {
  my ($to_shorten, $keywords) = @_;

  my $max_len = 30;
  my $min_entropy = 10;

  my $max_trunc = $max_len - $min_entropy - 1;

  return $to_shorten
    if length($to_shorten) <= $max_len;

  die "'keywords' needs to be an arrayref"
    if defined $keywords && ref $keywords ne 'ARRAY';

  my @keywords = @{$keywords || []};
  @keywords = $to_shorten unless @keywords;

  my $b36sum = Math::Base36::encode_base36(
    Math::BigInt->from_hex(
      '0x' . Digest::MD5::md5_hex($to_shorten)
    )
  );

  my ($concat_len, @lengths);
  for (@keywords) {
    $_ = ucfirst(lc($_));
    $_ =~ s/\_+(\w)/uc($1)/eg;

    push @lengths, length($_);
    $concat_len += $lengths[-1];
  }

  if ($concat_len > $max_trunc) {
    $concat_len = 0;
    @lengths = ();

    for (@keywords) {
      $_ =~ s/[aeiou]//g;

      push @lengths, length($_);
      $concat_len += $lengths[-1];
    }
  }

  if ($concat_len > $max_trunc) {
    my $trim_ratio = $max_trunc / $concat_len;

    for my $i (0 .. $#keywords) {
      $keywords[$i] = substr($keywords[$i], 0, int($trim_ratio * $lengths[$i]));
    }
  }

  my $fin = join('', @keywords);
  my $fin_len = length $fin;

  return sprintf('%s_%s',
    $fin,
    substr($b36sum, 0, $max_len - $fin_len - 1),
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Identifier - Shorten Oracle identifiers to the 30-character limit

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Oracle (pre-12.2) limits identifiers to 30 bytes. Both the SQL-generation
side (L<DBIO::Oracle::SQLMaker>, at query time) and the deploy side
(L<DBIO::Oracle::DDL>, when emitting generated sequence and index names)
need to fit names into that limit using the I<same> algorithm, so a name
generated at deploy time matches the name referenced at query time.

This module owns that single algorithm. Names already within the limit are
returned unchanged; longer names are CamelCase-compressed (vowels trimmed if
needed) and suffixed with a base36-encoded MD5 hash so the result is stable
and collision-resistant.

=func shorten

    my $name = DBIO::Oracle::Identifier::shorten($identifier);
    my $name = DBIO::Oracle::Identifier::shorten($identifier, \@keywords);

Returns C<$identifier> unchanged when it is 30 characters or fewer. Otherwise
returns a deterministic shortened form. The optional C<\@keywords> arrayref
controls the human-readable prefix (defaults to the identifier itself).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
