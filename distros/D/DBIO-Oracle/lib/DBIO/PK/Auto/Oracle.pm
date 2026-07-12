package DBIO::PK::Auto::Oracle;
# ABSTRACT: (DEPRECATED) Automatic primary key class for Oracle

use strict;
use warnings;

use base qw/DBIO::Core/;

__PACKAGE__->load_components(qw/PK::Auto/);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PK::Auto::Oracle - (DEPRECATED) Automatic primary key class for Oracle

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

Just load L<DBIO::PK::Auto> instead; auto-inc is now handled by Storage.

=head1 DESCRIPTION

This is a deprecated compatibility shim. The Oracle auto-increment handling it
used to provide now lives in L<DBIO::Oracle::Storage>, so loading this component
only pulls in L<DBIO::PK::Auto>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
