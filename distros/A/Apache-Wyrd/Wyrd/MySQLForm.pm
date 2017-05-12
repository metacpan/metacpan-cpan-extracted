#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::MySQLForm;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::SQLForm);
use Apache::Wyrd::Services::SAK qw(:db);
use warnings qw(all);
no warnings qw(uninitialized);

=pod

=head1 NAME

Apache::Wyrd::MySQLForm - MySQL variant on SQLForm Wyrd

=head1 SYNOPSIS

See Apache::Wyrd::SQLForm and Apache::Wyrd::Form

=head1 DESCRIPTION

This Wyrd implements the MySQL variant of the SQLForm Wyrd.  It differs
from the SQLForm Wyrd only in the C<_insert_id> method.

=head2 HTML ATTRIBUTES

See Apache::Wyrd::SQLForm and Apache::Wyrd::Form

=head2 PERL METHODS

I<(format: (returns) name (accepts))>

=over

=item (void) C<_insert_id> (DBI Statement Handle REF)

Implements "find the last inserted id" for MySQL.

=cut

#MySQL variant on getting the "just-inserted" record id
sub _insert_id {
	my ($self, $sh) = @_;
	return ($self->_variables->{$self->index} || $sh->{'mysql_insertid'});
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

NONE

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;