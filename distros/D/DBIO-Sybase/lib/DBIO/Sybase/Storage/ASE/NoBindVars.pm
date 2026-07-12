package DBIO::Sybase::Storage::ASE::NoBindVars;
# ABSTRACT: Support for Sybase ASE via DBD::Sybase without placeholders

use strict;
use warnings;

use base qw/
  DBIO::Storage::DBI::NoBindVars
  DBIO::Sybase::Storage::ASE
/;
use mro 'c3';
use Scalar::Util 'looks_like_number';

use namespace::clean;


sub _init {
  my $self = shift;
  $self->disable_sth_caching(1);
  $self->_identity_method('@@IDENTITY');
  $self->next::method(@_);
}

sub _fetch_identity_sql { 'SELECT ' . $_[0]->_identity_method }

my $number = sub { looks_like_number $_[0] };

my $decimal = sub { $_[0] =~ /^ [-+]? \d+ (?:\.\d*)? \z/x };

my %noquote = (
  int     => sub { $_[0] =~ /^ [-+]? \d+ \z/x },
  bit     => sub { $_[0] =~ /^[01]\z/ },
  money   => sub { $_[0] =~ /^\$ \d+ (?:\.\d*)? \z/x },
  float   => $number,
  real    => $number,
  double  => $number,
  decimal => $decimal,
  numeric => $decimal,
);


sub interpolate_unquoted {
  my $self = shift;
  my ($type, $value) = @_;

  return $self->next::method(@_) if not defined $value or not defined $type;

  if (my ($key) = grep { $type =~ /$_/i } keys %noquote) {
    return 1 if $noquote{$key}->($value);
  }
  elsif ($self->is_datatype_numeric($type) && $number->($value)) {
    return 1;
  }

  return $self->next::method(@_);
}


sub _prep_interpolated_value {
  my ($self, $type, $value) = @_;

  if ($type =~ /money/i && defined $value) {
    # change a ^ not followed by \$ to a \$
    $value =~ s/^ (?! \$) /\$/x;
  }

  return $value;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE::NoBindVars - Support for Sybase ASE via DBD::Sybase without placeholders

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Storage driver for Sybase ASE (Adaptive Server Enterprise) accessed via
L<DBD::Sybase> when your combination of L<DBD::Sybase> and libraries (most
likely FreeTDS) does not support C<?> style placeholders.
L<DBIO::Sybase::Storage::ASE> reblesses the storage into this class
automatically on connect when no placeholder support is detected.

This driver uses L<DBIO::Storage::DBI::NoBindVars> as a base, so bind variables
are interpolated (properly quoted) into the SQL query itself instead of being
passed as placeholders. Because that renders prepared statement caching
useless, caching is explicitly disabled.

One advantage of not using placeholders is that C<SELECT @@IDENTITY> works for
obtaining the last insert id of an C<IDENTITY> column, instead of having to do
C<SELECT MAX(col)> in a transaction as the base ASE driver does. This class
sets C<_identity_method> to C<@@IDENTITY> accordingly.

In all other respects it behaves as L<DBIO::Sybase::Storage::ASE>.

=head1 METHODS

=head2 interpolate_unquoted

Decides whether a given bind value should be interpolated into the SQL
unquoted, based on its column data type. Recognizes the Sybase numeric and
C<MONEY> types and only skips quoting when the value matches the expected
shape for that type. Falls back to
L<DBIO::Storage::DBI::NoBindVars/interpolate_unquoted> otherwise.

=head2 _prep_interpolated_value

Prepares a value for direct interpolation into the SQL query. For C<MONEY>
types it prefixes a C<$> sign when one is not already present.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE via L<DBD::Sybase>

=item * L<DBIO::Storage::DBI::NoBindVars> - placeholder-less interpolation base

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
