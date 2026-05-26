package DBIx::QuickORM::Role::STH;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak/;

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::STH - Role for statement-handle wrappers.

=head1 DESCRIPTION

The common interface for the statement-handle wrappers
(L<DBIx::QuickORM::STH> and its async variants). It defines the iteration
contract: fetch the result, check readiness, pull rows, and finalize.

Provides default C<cancel_supported> (false) and C<cancel> (croaks);
cancellable handles override both.

=head1 REQUIRED METHODS

C<connection>, C<source>, C<dialect>, C<only_one>, C<got_result>,
C<result>, C<ready>, C<done>, C<set_done>, C<clear>, C<next>.

=cut

sub cancel_supported { 0 }

sub cancel { croak "cancel() is not supported" }

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
