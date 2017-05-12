package DBIx::SchemaChecksum::App;
use 5.010;
use MooseX::App 1.21 qw(Config);
extends qw(DBIx::SchemaChecksum);

# ABSTRACT: App base class

use DBI;

option 'dsn' => (
    isa           => 'Str',
    is            => 'ro',
    required      => 1,
    documentation => q[DBI Data Source Name]
);
option 'user' => (
    isa           => 'Str',
    is            => 'ro',
    documentation => q[username to connect to database]
);
option 'password' => (
    isa           => 'Str',
    is            => 'ro',
    documentation => q[password to connect to database]
);
option [qw(+catalog +schemata +driveropts)] => ();

has '+dbh' => ( lazy_build => 1 );

sub _build_dbh {
    my $self = shift;
    return DBI->connect(
        $self->dsn, $self->user, $self->password,
        { RaiseError => 1 }    # TODO: set dbi->connect opts via App
    );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::App - App base class

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
