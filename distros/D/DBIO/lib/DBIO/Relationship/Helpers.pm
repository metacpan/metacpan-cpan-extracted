package DBIO::Relationship::Helpers;
# ABSTRACT: Load all standard relationship declaration components

use strict;
use warnings;

use base qw/DBIO::Base/;

__PACKAGE__->load_components(qw/
    Relationship::HasMany
    Relationship::HasOne
    Relationship::BelongsTo
    Relationship::ManyToMany
/);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship::Helpers - Load all standard relationship declaration components

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
