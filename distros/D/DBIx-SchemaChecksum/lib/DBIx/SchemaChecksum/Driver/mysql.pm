package DBIx::SchemaChecksum::Driver::mysql;
use utf8;

# ABSTRACT: MySQL driver for DBIx::SchemaChecksum

use namespace::autoclean;
use Moose::Role;

around '_build_schemadump_table' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;
    return if $schema =~ /information_schema/;

    die "Sorry, but mysql isn't supported at the moment, because it's introspection seems to be broken.\n";

    return $self->$orig($schema,$table);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::Driver::mysql - MySQL driver for DBIx::SchemaChecksum

=head1 VERSION

version 1.006

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Maroš Kollár <maros@cpan.org>

=item *

Klaus Ita <koki@worstofall.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
