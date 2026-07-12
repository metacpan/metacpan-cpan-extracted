package DBIO::Test::DateTimeParser;
# ABSTRACT: Minimal datetime parser for DBIO offline test storage

use strict;
use warnings;

sub new { bless {}, shift }

sub parse_datetime { $_[1] }
sub parse_date     { $_[1] }
sub parse_time     { $_[1] }

sub format_datetime { $_[1] }
sub format_date     { $_[1] }
sub format_time     { $_[1] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::DateTimeParser - Minimal datetime parser for DBIO offline test storage

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
