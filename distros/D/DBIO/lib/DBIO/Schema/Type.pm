package DBIO::Schema::Type;
# ABSTRACT: portable base-type vocabulary for multi-engine schemas

use strict;
use warnings;
use Carp qw/croak/;
use namespace::clean;

our @BASE_TYPES = qw/integer text char boolean numeric double blob timestamp/;
my %IS_BASE = map { $_ => 1 } @BASE_TYPES;

our %ALIAS = (
  (map { $_ => 'integer' } qw/int integer bigint smallint tinyint serial bigserial/),
  (map { $_ => 'text'    } qw/text varchar string clob mediumtext longtext/),
  (map { $_ => 'char'    } qw/char character/),
  (map { $_ => 'boolean' } qw/boolean bool/),
  (map { $_ => 'numeric' } qw/numeric decimal/),
  'double' => 'double', 'double precision' => 'double', real => 'double', float => 'double',
  (map { $_ => 'blob'    } qw/blob bytea binary varbinary/),
  (map { $_ => 'timestamp' } qw/timestamp datetime timestamptz/),
);

sub base_types   { @BASE_TYPES }
sub is_base_type { $IS_BASE{ $_[0] // '' } ? 1 : 0 }

sub normalize {
  my ($type) = @_;
  croak "undef data_type" unless defined $type;
  my $key = lc $type;
  $key =~ s/\(.*\)\s*$//;        # strip parameters: varchar(255) -> varchar
  $key =~ s/^\s+|\s+$//g;
  $key =~ s/\s+/ /g;
  my $base = $ALIAS{$key}
    or croak "unknown data_type '$type' (not in portable base-type vocabulary)";
  return $base;
}

sub canonical_column {
  my ($name, $info) = @_;
  my $base = normalize($info->{data_type});
  my %col = (
    column_name    => $name,
    base_type      => $base,
    not_null       => ($info->{is_nullable} ? 0 : 1),
    default        => $info->{default_value},
    auto_increment => ($info->{is_auto_increment} ? 1 : 0),
  );
  if ($base eq 'char') {
    $col{size} = $info->{size};
  }
  elsif ($base eq 'numeric') {
    my $s = $info->{size};
    @col{qw/precision scale/} = @$s if ref $s eq 'ARRAY';
  }
  return \%col;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Schema::Type - portable base-type vocabulary for multi-engine schemas

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
