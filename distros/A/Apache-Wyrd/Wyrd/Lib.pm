#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Lib;
our $VERSION = '0.98';
use strict;
use base qw(Apache::Wyrd::Interfaces::Stealth Apache::Wyrd);
use Apache::Wyrd::Services::FileCache;

=pod

=head1 NAME

Apache::Wyrd::Lib - Insert data from a file, as in SSI

=head1 SYNOPSIS

	<BASENAME::Lib file="libraryfile.html" />

=head1 DESCRIPTION

Wyrd equivalent of a simple Server-Side-Include.  Inserts a file from
the E<lt>DOCUMENTROOTE<gt>/lib/ directory into the HTML document at that
point.  Uses C<Apache::Wyrd::Services::FileCache> to reduce disk
accesses.

=head2 HTML ATTRIBUTES

=over

=item file

The file to insert.

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.  Consider limiting the /lib/
directory access via a server directive.

=cut

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception("Lib element must have a file attribute.")
		unless ($self->{file});
	my $file = join ('/', $self->dbl->req->document_root, 'lib', $self->file);
	$self->_data($self->get_cached($file));
}


=pod

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