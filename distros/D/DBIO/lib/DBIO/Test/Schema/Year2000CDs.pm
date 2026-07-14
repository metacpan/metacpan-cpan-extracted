package DBIO::Test::Schema::Year2000CDs;
# ABSTRACT: Test virtual view result class for 2000 CDs

use warnings;
use strict;

use base qw/DBIO::Test::Schema::CD/;

__PACKAGE__->table_class('DBIO::ResultSource::View');
__PACKAGE__->table('year2000cds');

# need to operate on the instance for things to work
__PACKAGE__->result_source_instance->view_definition( sprintf (
  "SELECT %s FROM cd WHERE year = '2000'",
  join (', ', __PACKAGE__->columns),
));

__PACKAGE__->belongs_to( artist => 'DBIO::Test::Schema::Artist' );
__PACKAGE__->has_many( tracks => 'DBIO::Test::Schema::Track', 'cd' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Year2000CDs - Test virtual view result class for 2000 CDs

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
