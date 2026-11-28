package DBIx::QuickORM::Dialect::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000031';

use parent 'DBIx::QuickORM::Dialect::MySQL';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::MariaDB - MariaDB dialect.

=head1 DESCRIPTION

MariaDB through L<DBD::MariaDB>. It inherits everything from
L<DBIx::QuickORM::Dialect::MySQL> except C<RETURNING> on C<INSERT> and
C<DELETE>, which MariaDB has, and its code for a failed C<CHECK>.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh);    # this class for a MariaDB server

=head1 PUBLIC METHODS

=over 4

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

True. C<UPDATE> has no C<RETURNING> (inherited, false).

=item \%kinds = $dialect->native_error_kinds

MySQL's codes, with MariaDB's code for a failed C<CHECK> (4025) in place of
MySQL's.

=back

=cut

sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

my %NATIVE_KIND = %{DBIx::QuickORM::Dialect::MySQL->native_error_kinds};
delete $NATIVE_KIND{3819};
$NATIVE_KIND{4025} = 'check_violation';

sub native_error_kinds { \%NATIVE_KIND }

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
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
