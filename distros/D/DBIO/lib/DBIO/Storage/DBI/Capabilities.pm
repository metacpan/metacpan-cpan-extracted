package DBIO::Storage::DBI::Capabilities;
# ABSTRACT: Two-tier capability probing for DBI storage drivers

use strict;
use warnings;

use base 'DBIO::Storage';
use mro 'c3';
use namespace::clean;


my @capabilities = (qw/
  insert_returning
  insert_returning_bound

  multicolumn_in

  placeholders
  typeless_placeholders

  join_optimizer
/);
__PACKAGE__->mk_group_accessors( dbms_capability => map { "_supports_$_" } @capabilities );
__PACKAGE__->mk_group_accessors( use_dbms_capability => map { "_use_$_" } (@capabilities ) );

# on by default, not strictly a capability (pending rewrite)
__PACKAGE__->_use_join_optimizer (1);
sub _determine_supports_join_optimizer { 1 };

sub set_use_dbms_capability {
  $_[0]->set_inherited ($_[1], $_[2]);
}

sub get_use_dbms_capability {
  my ($self, $capname) = @_;

  my $use = $self->get_inherited ($capname);
  return defined $use
    ? $use
    : do { $capname =~ s/^_use_/_supports_/; $self->get_dbms_capability ($capname) }
  ;
}

sub set_dbms_capability {
  $_[0]->_dbh_details->{capability}{$_[1]} = $_[2];
}

sub get_dbms_capability {
  my ($self, $capname) = @_;

  my $cap = $self->_dbh_details->{capability}{$capname};

  unless (defined $cap) {
    if (my $meth = $self->can ("_determine$capname")) {
      $cap = $self->$meth ? 1 : 0;
    }
    else {
      $cap = 0;
    }

    $self->set_dbms_capability ($capname, $cap);
  }

  return $cap;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::Capabilities - Two-tier capability probing for DBI storage drivers

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Capability detection for L<DBIO::Storage::DBI>. Uses a two-tier accessor
system:

A driver or user may define C<_use_X>, which blindly without any checks says
"(do not) use this capability" (C<use_dbms_capability> is an C<inherited>-type
accessor).

If C<_use_X> is undef, C<_supports_X> is queried. This is a simple-style
accessor which calls C<_determine_supports_X> and stores the return in a
slot on the storage object that is wiped on every C<$dbh> reconnection
(reconnection is not guaranteed to land on the same RDBMS version).
C<_determine_supports_X> does not need to exist on a driver — the runtime
C<< ->can >>-checks for it before calling.

The default capability list is below; drivers add their own with
C<< __PACKAGE__->mk_group_accessors(dbms_capability => '_supports_X') >>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
