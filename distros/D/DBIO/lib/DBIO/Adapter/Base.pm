package DBIO::Adapter::Base;
# ABSTRACT: per-driver base->native column type resolver (one-way)

use strict;
use warnings;

our $VERSION = '0.900004';

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

version 0.900004

=head1 METHODS

=head2 new

    my $adapter = $class->new(%args);

Blesses the argument hash. Subclasses are otherwise free to define their own
construction arguments.

=head2 to_native

    my $ddl_type = $adapter->to_native(\%canonical_column);

Resolves a L<DBIO::Schema::Type> canonical column hashref to this engine's
native DDL type string. Abstract -- subclasses must implement.

=head2 capabilities

    my $caps = $adapter->capabilities;

Hashref of engine traits the diff layer consults. Default:
C<< { supports_alter_column_type => 1 } >>; override to declare otherwise.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
