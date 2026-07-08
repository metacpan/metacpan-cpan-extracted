package DBIx::QuickORM::Dialect::MySQL::Percona;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Dialect::MySQL';
use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::MySQL::Percona - Percona variant of the MySQL dialect.

=head1 DESCRIPTION

Vendor-specific subclass of L<DBIx::QuickORM::Dialect::MySQL> for Percona
Server. It inherits the MySQL behavior unchanged; C<init> refuses to attach to
a server that does not identify as Percona.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::MySQL::Percona->new(dbh => $dbh, db_name => $name);

=head1 PUBLIC METHODS

=over 4

=item $name = $dialect->dialect_name

Returns C<'MySQL::Percona'>.

=cut

sub dialect_name { 'MySQL::Percona' }

=pod

=item $dialect->init

Validates the connection and refuses a server that does not identify as
Percona.

=back

=cut

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $vendor = $self->db_vendor;
    croak "The mysql vendor is '$vendor' not Percona" if $vendor && $vendor !~ m/Percona/i;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
