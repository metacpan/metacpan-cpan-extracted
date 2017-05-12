package DBIx::SchemaChecksum::App::Checksum;
use 5.010;

# ABSTRACT: DBIx::SchemaChecksum command checksum

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);

option 'show_dump' => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => q[Show the raw database dump structure],
    default       => 0,
);

sub run {
    my $self = shift;

    say $self->checksum;
    say $self->_schemadump if $self->show_dump;
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::App::Checksum - DBIx::SchemaChecksum command checksum

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
