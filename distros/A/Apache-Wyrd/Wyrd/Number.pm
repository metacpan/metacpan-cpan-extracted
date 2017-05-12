#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Number;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(commify);

my %number = ();

=pod

=head1 NAME

Apache::Wyrd::Number - Format Numerals or Translate to Written (English)

=head1 SYNOPSIS

    There are
    <BASENAME::Number>
      <BASENAME::Lookup query="select count(stones) from dancers" />
    </BASENAME::Number>
    stones in the dancers.

=head1 DESCRIPTION

NONE

=head2 HTML ATTRIBUTES

=over

=item translate

Translate the number into another symbol-system.  Currently only B<english>
is supported as an option.

=item decimals

How many decimals to round the number to (not compatible with 
B<translate>).

=item currency

What currency symbol to use to the left of the number.  (Not compatible with
B<translate>)

=item leader

string to put to the left of the currency symbol, if applicable.

=item tail

string to put to the right of the number

=item flags

=over

=item capitalize

Capitalize the first letter of a "translated" Number

=item commify

Put delineators into an "untranslated" Number.  Uses the ',' symbol

=back

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<_translate> (scalar, scalar)

Accepts a value and a "mode" string.  Based on the mode string, will perform
a translation of the number in the mode specified by the B<translate>
attribute, as long as the number is between 0 and 999.  This method is meant
to be instantiated.  The version included in this module will translate most
of the numbers one might have to spell out to suit a style, as is commonly
required when the number appears at the beginning of a sentence.  Currently,
only B<english> is supported as an option.  This number will be capitalized
if the B<capitalize> flag is set.

=cut

sub _translate {
	my ($self, $data, $mode) = @_;
	if ($mode eq 'english') {
		unless ($number{'0'} eq 'zero') {
			my @base = qw(one two three four five six seven eight nine);
			my @teens = qw(ten eleven twelve thirteen forteen fifteen sixteen seventeen eighteen nineteen);
			my @decades = qw(twenty thirty forty fifty sixty seventy eighty ninety);
			my $count = 0;
			foreach my $century ('', @base) {
				$number{$count++} = "$century hundred";
				$century = "$century hundred " if ($century);
				map {$number{$count++} = $century . $_} (@base, @teens);
				foreach my $decade (@decades) {
					$number{$count++} = $century . $decade;
					map {$number{$count++} = "$century$decade-$_"} (@base);
				}
			}
			$number{'0'} = 'zero';
		}
		if ($number{$data}) {
			return $number{$data};
		} else {
			$self->_warn("Number $data is too complex to translate");
			return $data;
		}
	}
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	my $data = $self->_data;
	$data =~ s/[^\d.]//g;
	my $leader = $self->{'leader'};
	my $tail = $self->{'tail'};
	my $currency = $self->{'currency'};
	my $translation = $self->{'translate'};
	if ($translation) {
		$data = $self->_translate($data, $translation);
		$data = ucfirst($data) if ($self->_flags->capitalize);
		$self->_data($leader . $data . $tail);
	} else {
		if (defined($self->{'decimals'})) {
			my $decimals = $self->{'decimals'};
			$decimals += 0;#force mathmatical value
			$data = int($data * (10 ** $decimals) + .5);
			$data =~ s/(.{$decimals})$/.$1/ if ($decimals);
		}
		if ($self->_flags->commify) {
			$data = commify($data);
		}
		$self->_data($leader . $currency . $data . $tail);
	}
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