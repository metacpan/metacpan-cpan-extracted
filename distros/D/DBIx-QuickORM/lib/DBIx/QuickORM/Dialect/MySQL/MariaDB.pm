package DBIx::QuickORM::Dialect::MySQL::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Dialect::MySQL';
use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::MySQL::MariaDB - MariaDB variant of the MySQL dialect.

=head1 DESCRIPTION

Vendor-specific subclass of L<DBIx::QuickORM::Dialect::MySQL> for MariaDB
servers. MariaDB supports C<RETURNING> on insert and delete but not on update,
and C<init> refuses to attach to a server that does not identify as MariaDB.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::MySQL::MariaDB->new(dbh => $dbh, db_name => $name);

=head1 PUBLIC METHODS

=over 4

=item $name = $dialect->dialect_name

Returns C<'MySQL::MariaDB'>.

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

C<RETURNING> support flags: supported for insert and delete, not for update.

=cut

sub dialect_name { 'MySQL::MariaDB' }

sub supports_returning_update { 0 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

=pod

=item $dialect->init

Validates the connection and refuses a server that does not identify as
MariaDB.

=back

=cut

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $vendor = $self->db_vendor;
    die "The mysql vendor is '$vendor' not MariaDB" if $vendor && $vendor !~ m/MariaDB/i;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
