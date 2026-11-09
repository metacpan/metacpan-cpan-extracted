package DBIO::Shortcut::pg;
# ABSTRACT: `use DBIO -pg` shortcut for the PostgreSQL driver

use strict;
use warnings;

our $VERSION = '0.900004';



sub apply { DBIO->apply_driver($_[1], 'PostgreSQL') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Shortcut::pg - `use DBIO -pg` shortcut for the PostgreSQL driver

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The stub L<DBIO> loads for the C<-pg> shortcut:

    package MyApp::Schema;
    use DBIO Schema => -pg;

    package MyApp::Schema::Result::User;
    use DBIO -pg;

It is not used directly.

=head1 METHODS

=head2 apply

    DBIO::Shortcut::pg->apply($class);

Called by C<use DBIO> with the class that named C<-pg>. Hands it to
L<DBIO/apply_driver> for the driver C<PostgreSQL>: a schema class gets
C<+DBIO::PostgreSQL::Storage> as its C<storage_type>, a result class loads
L<DBIO::PostgreSQL::Result>. A schema class does not get the
L<DBIO::PostgreSQL> component that way; C<pg_schemas> and the other
declarations of it need C<load_components('PostgreSQL')>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
