package DBIO::Test::Schema::ResultDDL::Result::CD;
# ABSTRACT: Test Cake result class for the cd table
use DBIO::Cake;
table 'cd';
col id        => integer, unsigned, auto_inc;
col artist_id => integer, unsigned;
col title     => varchar(255);
col year      => integer, null;
primary_key 'id';
belongs_to artist => 'DBIO::Test::Schema::ResultDDL::Result::Artist', 'artist_id';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::ResultDDL::Result::CD - Test Cake result class for the cd table

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
