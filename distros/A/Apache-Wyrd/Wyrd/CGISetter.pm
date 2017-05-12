use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::CGISetter;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Stealth Apache::Wyrd::Interfaces::Setter Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::CGISetter - Set values in a Wyrd according to CGI state

=head1 SYNOPSIS

	<BASENAME::CGISetter><h1>$:title</h1></BASENAME::CGISetter>

=head1 DESCRIPTION

Sets variables in the space it encloses based on CGI params.  The variables are denoted
by the sequence $:variable_name where the variable_name follows perl rules for variable
names.

This module uses the C<Apache::Wyrd::Interfaces::Setter> conventions.

=head2 HTML ATTRIBUTES

=over

=item style

three optional styles are available

=over 2

=item style="escape"

substitute HTML-interpretable characters with their entity equivalents

=item style="query" 

Properly quote the values for use in SQL queries

=item style="clear"

Remove any undefined values, so that there are no remaining $:variable placemarkers.

=back

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.

Does not handle multiple CGI values, but takes the first handed to it by the
Apache::Request->param call.

=cut

sub _format_output {
	my ($self) = @_;
	my $data = undef;
	if ($self->{'style'} eq undef) {
		$data = $self->_set;
	} elsif ($self->{'style'} =~ /\bescape\b/i) {
		$data = $self->_cgi_escape_set;
	} elsif ($self->{'style'} =~ /\bquery|sql\b/i) {
		$data = $self->_cgi_quote_set;
	} elsif ($self->{'style'} =~ /\bclear\b/i) {
		$data = $self->_clear_set;
	} else {
		$self->_raise_exception("Unknown style: " . $self->{'style'});
	}
	$self->_data($data);
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Interfaces::Setter

Implementation of a common template format for Wyrds

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;