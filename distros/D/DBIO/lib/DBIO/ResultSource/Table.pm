package DBIO::ResultSource::Table;
# ABSTRACT: Table object

use strict;
use warnings;

use DBIO::ResultSet;

use base qw/DBIO::Base/;
__PACKAGE__->load_components(qw/ResultSource/);


sub from { shift->name; }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSource::Table - Table object

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

=head1 DESCRIPTION

Table object that inherits from L<DBIO::ResultSource>.

=head1 METHODS

=head2 from

Returns the FROM entry for the table (i.e. the table name)

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
