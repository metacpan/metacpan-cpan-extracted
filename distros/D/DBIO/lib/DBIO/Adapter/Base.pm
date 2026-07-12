package DBIO::Adapter::Base;
# ABSTRACT: per-driver base->native column type resolver (one-way)

use strict;
use warnings;
use Carp qw/croak/;
use namespace::clean;

sub new { my ($class, %args) = @_; bless { %args }, $class }

# to_native(\%canonical_column) -> native DDL type string. Subclasses implement.
sub to_native { croak ref($_[0]) . "::to_native not implemented" }

# capabilities -> hashref of engine traits the diff consults.
sub capabilities { return { supports_alter_column_type => 1 } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Adapter::Base - per-driver base->native column type resolver (one-way)

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
