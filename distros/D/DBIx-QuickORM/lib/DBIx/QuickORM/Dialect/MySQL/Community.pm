package DBIx::QuickORM::Dialect::MySQL::Community;
use strict;
use warnings;

our $VERSION = '0.000025';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Dialect::MySQL';
use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::MySQL::Community - MySQL Community variant of the MySQL dialect.

=head1 DESCRIPTION

Vendor-specific subclass of L<DBIx::QuickORM::Dialect::MySQL> for MySQL
Community Server. It inherits the MySQL behavior unchanged; C<init> refuses to
attach to a server that does not identify as Community.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::MySQL::Community->new(dbh => $dbh, db_name => $name);

=head1 PUBLIC METHODS

=over 4

=item $name = $dialect->dialect_name

Returns C<'MySQL::Community'>.

=cut

sub dialect_name { 'MySQL::Community' }

=pod

=item $dialect->init

Validates the connection and refuses a server that does not identify as
Community.

=back

=cut

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $vendor = $self->db_vendor;
    croak "The mysql vendor is '$vendor' not Community" if $vendor && $vendor !~ m/Community/i;
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
