package DBIO::Test::Schema::ArtistSourceName;
# ABSTRACT: Test result class for custom source name on the artist table

use warnings;
use strict;

use base 'DBIO::Test::Schema::Artist';
__PACKAGE__->table(__PACKAGE__->table);
__PACKAGE__->source_name('SourceNameArtists');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::ArtistSourceName - Test result class for custom source name on the artist table

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
