package DBIO::MySQL::EV::ConnectInfo;
# ABSTRACT: MySQL/MariaDB connection-info utilities for DBIO async driver

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw( dbi_to_conninfo );


sub dbi_to_conninfo {
  my ($info) = @_;
  my ($dsn, $user, $pass, $attrs) = @$info;
  die "expected dbi:mysql:/dbi:MariaDB:... DSN, got: " . (defined $dsn ? $dsn : '(undef)') . "\n"
    unless defined $dsn && $dsn =~ s{^dbi:(?:mysql(?:\.\w+)?|mariadb):(.+)$}{$1}i;
  my $params = $1;
  my %h;
  for my $kv (split /;/, $params) {
    next unless $kv =~ /\S/;
    my ($k, $v) = split /=/, $kv, 2;
    $k = lc $k;
    $k = 'database' if $k eq 'dbname';
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

DBIO::MySQL::EV::ConnectInfo - MySQL/MariaDB connection-info utilities for DBIO async driver

=head1 VERSION

version 0.900001

=func dbi_to_conninfo

  my $async_info = dbi_to_conninfo([ 'dbi:MariaDB:database=test;host=localhost', $user, $pass, \%attrs ]);

Translate a DBI-style connect-info arrayref (C<[$dsn, $user, $pass, \%attrs]>,
as produced by the sync L<DBIO::MySQL::Storage>) into the async
C<[ \%conninfo, \%opts ]> shape consumed by L<DBIO::MySQL::EV::Storage>.

The C<dbi:mysql:> / C<dbi:MariaDB:> DSN is parsed into named L<EV::MariaDB>
parameters (C<host>, C<port>, C<database>, ...); C<dbname> is normalised to
C<database> (EV::MariaDB's spelling). C<$user> / C<$pass> fill in C<user> /
C<password> when not already present in the DSN. A C<pool_size> attribute, if
given, is carried into the conninfo hash. Dies unless the DSN is in a
C<dbi:mysql:>-family form, since EV::MariaDB does not understand the DSN string.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
