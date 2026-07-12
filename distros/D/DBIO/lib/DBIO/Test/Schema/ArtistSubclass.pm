package DBIO::Test::Schema::ArtistSubclass;
# ABSTRACT: Test result subclass of the artist table

use warnings;
use strict;

use base 'DBIO::Test::Schema::Artist';

__PACKAGE__->table(__PACKAGE__->table);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::ArtistSubclass - Test result subclass of the artist table

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
