use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::ShowParams;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::ShowParams - Dump CGI state to browser for debugging

=head1 SYNOPSIS

	<BASENAME::ShowParams />

=head1 DESCRIPTION

Simply dumps the CGI parameters received.

=head2 HTML ATTRIBUTES

NONE

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _generate_output method.

=cut

sub _generate_output {
	my ($self) = @_;
	my @params = $self->dbl->param;
	my $out = undef;
	foreach my $param (sort @params) {
		my @value = $self->dbl->param($param);
		$out .= "<LI>$param: " . join(', ', sort @value);
	}
	return "<UL>$out</UL>";
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