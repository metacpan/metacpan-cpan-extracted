#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::CGICond;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Stealth Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(:hash);

=pod

=head1 NAME

Apache::Wyrd::CGICond - Selectively display or hide data based on CGI state

=head1 SYNOPSIS

    <Apache::Wyrd::CGICond var="sam">
      This text will appear if the CGI variable "sam"
      is set (has a value other than ''/0/undef)
    </Apache::Wyrd::CGICond>

    <Apache::Wyrd::CGICond var="!sam,pete">
      This text will appear if the CGI variables "sam" and "pete"
      are null (have a value of ''/0/undef)
    </Apache::Wyrd::CGICond>

    <Apache::Wyrd::CGICond var="?sam,pete">
      This text will appear if either of the CGI variables
      "sam" and "pete" are set
    </Apache::Wyrd::CGICond>

    <Apache::Wyrd::CGICond var="?!sam,pete">
      This text will appear if either of the CGI
      variables "sam" and "pete" are null
    </Apache::Wyrd::CGICond>

=head1 DESCRIPTION

Hides or displays enclosed text depending on the undefined/defined value
of CGI parameters.  Uses the Apache::Wyrd::Interfaces::Setter style meta
characters to determine the behavior in relation to the named CGI
parameters.

=head2 HTML ATTRIBUTES

=over

=item var

Defines the salient variable(s).  Multiple values are separated with
commas or whitespace.

The first characters of this value provide modifiers to determine the
behavior.  If missing, the test will be simply for the availability of
ALL the values.

a '?' will show the text if ANY of the variables are non-null, a '!'
will do so if NONE of the variables are non-null.  A '?!' will show the
text if any of the variables are null.  (see the SYNOPSIS)

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	my $var = $self->{'var'};
	my $nor = $var =~ s/^(\!\?|\?\!)//;
	my $not = $var =~ s/^\!//;
	my $or = $var =~ s/^\?//;
	my @vars = token_parse($var);
	if ($not) {
		my $set = 1;
		foreach my $var (@vars) {
			$set = 0 if($self->dbl->param($var));
		}
		$self->{'_data'} = undef unless ($set);
	} elsif ($or) {
		my $set = 0;
		foreach my $var (@vars) {
			$set = 1 if($self->dbl->param($var));
		}
		$self->{'_data'} = undef unless ($set);
	} elsif ($nor) {
		my $set = 0;
		foreach my $var (@vars) {
			$set = 1 if (not($self->dbl->param($var)));
		}
		$self->{'_data'} = undef unless ($set);
	} else {
		my $set = 1;
		foreach my $var (@vars) {
			$set = 0 unless($self->dbl->param($var));
		}
		$self->{'_data'} = undef unless ($set);
	}
	return;
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

=head1 TODO

Variant which operates on the definition of the variable, not it's non-null status, but that might be too un-perlish :).

=cut

1;