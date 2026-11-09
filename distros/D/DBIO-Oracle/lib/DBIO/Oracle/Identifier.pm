package DBIO::Oracle::Identifier;
# ABSTRACT: Shorten Oracle identifiers to the 30-character limit

use strict;
use warnings;

our $VERSION = '0.900004';

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


sub quote {
  my ($name) = @_;
  $name =~ s/"/""/g;
  return qq{"$name"};
}


sub split_table {
  my ($name) = @_;
  return ($1, $2) if $name =~ /\A([^.]+)\.(.+)\z/s;
  return (undef, $name);
}


sub quote_table {
  my ($schema, $table) = split_table($_[0]);
  return defined $schema ? quote(_mapped($schema)) . '.' . quote($table) : quote($table);
}


sub quote_in {
  my ($table_key, $name) = @_;
  my ($schema) = split_table($table_key);
  return defined $schema ? quote(_mapped($schema)) . '.' . quote($name) : quote($name);
}


our %SCHEMA_MAP;

sub _mapped { $SCHEMA_MAP{ $_[0] } // $_[0] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Identifier - Shorten Oracle identifiers to the 30-character limit

=head1 VERSION

version 0.900004

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

=head1 ATTRIBUTES

=head2 %SCHEMA_MAP

    local %DBIO::Oracle::Identifier::SCHEMA_MAP = (OWNX => 'DBIO_TMP_1_2_1');

The schemas L</quote_table> and L</quote_in> write are looked up here first:
a schema with an entry is written as its value. Empty by default. It is how
L<DBIO::Oracle::Deploy> writes the install DDL of a diff with the temporary
user of each foreign schema in place of the real one; set it with
C<local>, for the one call.

=head1 METHODS

=head2 shorten

    my $name = DBIO::Oracle::Identifier::shorten($identifier);
    my $name = DBIO::Oracle::Identifier::shorten($identifier, \@keywords);

Returns C<$identifier> unchanged when it is 30 characters or fewer. Otherwise
returns a deterministic shortened form. The optional C<\@keywords> arrayref
controls the human-readable prefix (defaults to the identifier itself).

=head2 quote

    my $sql_name = DBIO::Oracle::Identifier::quote($name);

Returns C<$name> as a double-quoted identifier, exactly as spelled (a double
quote inside is doubled). The statements of the diff operations
(L<DBIO::Oracle::Diff::Table>, L<DBIO::Oracle::Diff::Index>,
L<DBIO::Oracle::Diff::ForeignKey>) write every name this way, as
L<DBIO::Oracle::DDL> does, so that a table the diff creates is the one the
install creates and the storage, which quotes with C<sql_quote_char> C<">,
finds it.

=head2 split_table

    my ($schema, $table) = DBIO::Oracle::Identifier::split_table('OWNX.item');
    # ('OWNX', 'item');  a bare 'item' gives (undef, 'item')

A table name that holds a dot is C<schema.table>: the text before
the first dot is the schema (on Oracle a user), the rest the table. Both halves
keep their spelling. A name with an empty half (C<.t>, C<x.>) has no schema and
is returned whole; L<DBIO::Oracle::DDL> refuses such a name.

=head2 quote_table

    my $sql_name = DBIO::Oracle::Identifier::quote_table('OWNX.item');
    # "OWNX"."item"

Like L</quote>, for a table key that may be C<schema.table>: schema and table
are quoted separately, each exactly as spelled. A bare name is quoted as
L</quote> does.

=head2 quote_in

    my $sql_name = DBIO::Oracle::Identifier::quote_in($table_key, $name);
    # "OWNX"."name" for 'OWNX.item'; "name" for a bare table key

An object that lives in the schema of its table (an index, a sequence, a
trigger): C<$name> quoted, behind the schema of C<$table_key> when it has one.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
