package DBIO::PostgreSQL::EV::ConnectInfo;
# ABSTRACT: PostgreSQL connection string utilities for DBIO async driver

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw( escape_conninfo conninfo_string dbi_to_conninfo );


sub escape_conninfo {
  my $val = shift;
  return "''" unless defined $val && length $val;
  return $val unless $val =~ /[\s'\\]/;
  $val =~ s/\\/\\\\/g;
  $val =~ s/'/\\'/g;
  return "'$val'";
}


sub conninfo_string {
  my ($ci) = @_;
  return $ci unless ref $ci;

  return join(' ', map { "$_=" . escape_conninfo($ci->{$_}) }
    grep { defined $ci->{$_} } keys %$ci);
}


sub dbi_to_conninfo {
  my ($info) = @_;
  my ($dsn, $user, $pass, $attrs) = @$info;
  die "expected dbi:Pg:... DSN, got: " . (defined $dsn ? $dsn : '(undef)') . "\n"
    unless defined $dsn && $dsn =~ s{^dbi:Pg:(.+)$}{$1}i;
  my $params = $1;
  my %h;
  for my $kv (split /;/, $params) {
    next unless $kv =~ /\S/;
    my ($k, $v) = split /=/, $kv, 2;
    $k = lc $k;
    $k = 'dbname' if $k eq 'database';
    $h{$k} = $v;
  }
  $h{user}     //= $user if defined $user;
  $h{password} //= $pass if defined $pass;
  my %opts;
  $h{pool_size} = $attrs->{pool_size} if ref $attrs eq 'HASH' && $attrs->{pool_size};
  return [ \%h, \%opts ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::ConnectInfo - PostgreSQL connection string utilities for DBIO async driver

=head1 VERSION

version 0.900001

=func escape_conninfo

  my $escaped = escape_conninfo($value);

Escape a single connection parameter value for use in a libpq conninfo string.
Handles whitespace, single quotes, and backslashes.

=func conninfo_string

  my $str = conninfo_string({ host => 'localhost', port => 5432 });

Convert a hashref of connection parameters into a libpq connection string.
Skips undefined values.

=func dbi_to_conninfo

  my $async_info = dbi_to_conninfo([ 'dbi:Pg:dbname=test;host=localhost', $user, $pass, \%attrs ]);

Translate a DBI-style connect-info arrayref (C<[$dsn, $user, $pass, \%attrs]>,
as produced by the sync L<DBIO::PostgreSQL::Storage>) into the async
C<[ \%conninfo, \%opts ]> shape consumed by L<DBIO::PostgreSQL::EV::Storage>.

The C<dbi:Pg:> DSN is parsed into named libpq parameters (C<dbname>, C<host>,
C<port>, ...); C<database> is normalised to C<dbname>. C<$user> / C<$pass> fill
in C<user> / C<password> when not already present. A C<pool_size> attribute, if
given, is carried into the conninfo hash. Dies unless the DSN is in C<dbi:Pg:>
form, since libpq does not understand it.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
