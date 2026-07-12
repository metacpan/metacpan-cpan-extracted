package DBIO::Test::Taint::Classes::Auto;
# ABSTRACT: Test class for taint mode with auto-loading

use warnings;
use strict;

use base 'DBIO::Core';
__PACKAGE__->table('test');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Taint::Classes::Auto - Test class for taint mode with auto-loading

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
