package DBIx::QuickORM::Schema::View;
use strict;
use warnings;

our $VERSION = '0.000021';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use parent 'DBIx::QuickORM::Schema::Table';
use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Schema::View - Schema object for a database view.

=head1 DESCRIPTION

A view behaves exactly like a L<DBIx::QuickORM::Schema::Table> (columns,
links, etc.); the only difference is that C<is_view> returns true, so code
can distinguish a view from a real table.

=cut

sub is_view { 1 }

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
