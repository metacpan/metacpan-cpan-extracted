package DBIO::Test::SQLMRebase;
# ABSTRACT: Test SQLMaker subclass with select call counting

use warnings;
use strict;

our @ISA = qw( DBIO::SQLMaker::ClassicExtensions SQL::Abstract );

__PACKAGE__->mk_group_accessors( simple => '__select_counter' );

sub select {
  $_[0]->{__select_counter}++;
  shift->next::method(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::SQLMRebase - Test SQLMaker subclass with select call counting

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
