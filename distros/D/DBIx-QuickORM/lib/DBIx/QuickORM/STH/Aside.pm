package DBIx::QuickORM::STH::Aside;
use strict;
use warnings;

our $VERSION = '0.000021';

use Carp qw/croak/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::STH';
with 'DBIx::QuickORM::Role::Async';

use parent 'DBIx::QuickORM::STH::Async';
use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::STH::Aside - Async statement handle run on an aside connection.

=head1 DESCRIPTION

A L<DBIx::QuickORM::STH::Async> variant whose query runs on a separate
"aside" connection rather than the primary one. It behaves exactly like the
async handle except that finalizing it releases the aside connection back to
the owning connection.

=head1 SYNOPSIS

    while (my $row_hr = $sth->next) { ... }

=head1 PUBLIC METHODS

=over 4

=item $sth->clear

Release the aside connection back to the owning connection.

=back

=cut

sub clear { $_[0]->{+CONNECTION}->clear_aside($_[0]) }

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
