package DBIx::SchemaChecksum::Driver::SQLite;

# ABSTRACT: SQLite driver for DBIx::SchemaChecksum
our $VERSION = '1.106'; # VERSION

use utf8;
use namespace::autoclean;
use Moose::Role;

around '_build_schemadump_table' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;

    return
        if ($table eq 'sqlite_temp_master' && $schema eq 'temp')
        || ($table eq 'sqlite_sequence' && $schema eq 'main')
        || ($table eq 'sqlite_master' && $schema eq 'main');

    return $self->$orig($schema,$table);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::Driver::SQLite - SQLite driver for DBIx::SchemaChecksum

=head1 VERSION

version 1.106

=head1 DESCRIPTION

Ignore some internal sqlite tables

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@plix.at>

=item *

Maroš Kollár <cpan@k-1.com>

=item *

Klaus Ita

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
