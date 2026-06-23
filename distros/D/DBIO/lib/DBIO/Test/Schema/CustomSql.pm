package DBIO::Test::Schema::CustomSql;
# ABSTRACT: Test result class using a custom SQL query as source

use warnings;
use strict;

use base qw/DBIO::Test::Schema::Artist/;

__PACKAGE__->table('dummy');

__PACKAGE__->result_source_instance->name(\<<SQL);
  ( SELECT a.*, cd.cdid AS cdid, cd.title AS title, cd.year AS year
  FROM artist a
  JOIN cd ON cd.artist = a.artistid
  WHERE cd.year = ?)
SQL

sub sqlt_deploy_hook { $_[1]->schema->drop_table($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::CustomSql - Test result class using a custom SQL query as source

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
