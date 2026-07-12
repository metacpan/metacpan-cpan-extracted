package # moar hide
  DBIO::Test::SQLTracerObj;
# ABSTRACT: SQL statement tracing object for test diagnostics

use strict;
use warnings;

use base 'DBIO::Storage::Statistics';
use Sub::Util 'set_subname';
use namespace::clean;

sub query_start { push @{$_[0]{sqlbinds}}, [ ($_[1] =~ /^\s*(\S+)/)[0], [ $_[1], @{ $_[2]||[] } ] ] }

# who the hell came up with this API >:(
for my $txn (qw(begin rollback commit)) {
  no strict 'refs';
  *{"txn_$txn"} = set_subname "txn_$txn" => sub { push @{$_[0]{sqlbinds}}, [ uc $txn => [ uc $txn ] ] };
}

sub svp_begin { push @{$_[0]{sqlbinds}}, [ SAVEPOINT => [ "SAVEPOINT $_[1]" ] ] }
sub svp_release { push @{$_[0]{sqlbinds}}, [ RELEASE_SAVEPOINT => [ "RELEASE $_[1]" ] ] }
sub svp_rollback { push @{$_[0]{sqlbinds}}, [ ROLLBACK_TO_SAVEPOINT => [ "ROLLBACK TO $_[1]" ] ] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::SQLTracerObj - SQL statement tracing object for test diagnostics

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
