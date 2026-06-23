package DBIO::Test::Namespace::OtherRslt::D;
# ABSTRACT: Test fixture for namespace resolution

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('d');
__PACKAGE__->add_columns('d');
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Namespace::OtherRslt::D - Test fixture for namespace resolution

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
