package App::Tarotplane::Cards;
our $VERSION = '2.00';
use 5.016;
use strict;
use warnings;

use Carp;
use List::Util qw(shuffle);

use constant {
	CARD_TERM => 0,
	CARD_DEF  => 1,
};

sub _read_cardfile {

	my $file = shift;

	my @cards;

	open my $fh, '<', $file or croak "Could not open $file: $!";

	my $card = {};

	my $cn = 1;

	my $state = CARD_TERM;

	my $l = '';
	while (defined $l) {

		$l = readline $fh;

		if (not defined $l or $l eq "%\n") {

			# Blank cards are okay
			next if not defined $card->{Term};

			croak "No definition for card #$cn in $file"
				unless $state == CARD_DEF;

			# Trim leading/trailing whitespace
			$card->{Term}       =~ s/^\s+|\s+$//g;
			$card->{Definition} =~ s/^\s+|\s+$//g;

			# Truncate whitespace
			$card->{Term}       =~ s/\s+/ /g;
			$card->{Definition} =~ s/\s+/ /g;

			## Now interpret some escape codes
			# '\:' -> ':'
			$card->{Term}       =~ s/\\:/:/g;
			$card->{Definition} =~ s/\\:/:/g;

			# '\n' -> line break
			$card->{Term}       =~ s/\\n/\n/g;
			$card->{Definition} =~ s/\\n/\n/g;

			# No longer need '\\' substitution null byte
			$card->{Term}       =~ s/\0//g;
			$card->{Definition} =~ s/\0//g;

			push @cards, $card;
			$card = {};
			$state = CARD_TERM;

			$cn++;

			next;

		}

		# Skip comments and blanks
		my $first = substr $l, 0, 1;
		next if $first eq '#' or $first eq "\n";

		# Substitute '\\' now so that '\\:' does not count as an escaped colon.
		# The null byte is added so that the subsequent substitutions do not
		# try to replace any '\\' escaped backslash.
		$l =~ s/\\\\/\\\0/g;

		if ($state == CARD_TERM) {
			# Does card contain non-escaped colon?
			if ($l =~ /(^|[^\\]):/) {
				my (undef,
					$te,
					$de
				) = split(/(^.*[^\\]):/, $l, 2);
				$card->{Term}       .= $te || '';
				$card->{Definition} .= $de || '';
				$state = CARD_DEF;
			} else {
				$card->{Term} .= $l;
			}
		} else {
			$card->{Definition} .= $l;
		}

	}

	close $fh;

	croak "No cards found in $file" unless @cards;

	return @cards;

}

sub new {

	my $class = shift;
	my @files = @_;

	my $self = {
		Cards   => [],
		CardNum => 0,
	};

	foreach my $f (@files) {

		my @cards = _read_cardfile($f);

		push @{$self->{Cards}}, @cards;
		$self->{CardNum} += scalar @cards;

	}

	bless $self, $class;
	return $self;

}

sub get {

	my $self = shift;
	my $get  = shift;

	if (defined $self->{$get}) {
		return $self->{$get};
	}

	return undef;

}

sub card {

	my $self = shift;
	my $card = shift;

	return $self->{Cards}->[$card] // undef;

}

sub card_side {

	my $self = shift;
	my $card = shift;
	my $side = shift;

	if ($side ne 'Term' and $side ne 'Definition') {
		croak "side must be either 'Term' or 'Definition'";
	}

	if (defined $self->{Cards}->[$card]) {
		return $self->{Cards}->[$card]->{$side};
	}

	return undef;

}

sub order_deck {

	my $self = shift;
	my $by   = shift // 'Term';

	if ($by ne 'Term' and $by ne 'Definition') {
		croak "Must order deck either by 'Term' or 'Definition'";
	}

	@{$self->{Cards}} = sort {
		$a->{$by} cmp $b->{$by}
	} @{$self->{Cards}};

}

sub shuffle_deck {

	my $self = shift;

	@{$self->{Cards}} = shuffle @{$self->{Cards}};

}

1;



=head1 NAME

App::Tarotplane::Cards - Read tarotplane card files

=head1 SYNOPSIS

  use App::Tarotplane::Cards;

  $deck = App::Tarotplane::Cards->new(@files);

  $deck->order_deck('Term');

  $deck->shuffle_deck();

  $card0 = $deck->card(0);

  $term1 = $deck->card_side(1, 'Term');

=head1 DESCRIPTION

App::Tarotplane::Cards is a module used by L<tarotplane> to read and organize
decks of card files from text files. For information on how to format card
files, consult the relevant documentation in the L<tarotplane> manual page.

=head1 Object Methods

=head2 App::Tarotplane::Cards->new(@files)

Reads cards from @files, and returns an App::Tarotplane::Cards object. To read
more about the card file format, consult the L<tarotplane> manual page.

=head2 $deck->get($get)

Get $get from $deck. The following can be gotten:

=over 4

=item Cards

Array ref of cards.

=item CardNum

Number of cards.

=back

Returns undef on failure.

=head2 $deck->card($n)

Return $n-th card from deck. The card will be a hash ref that looks like this

  {
    Term       => 'term string',
    Definition => 'definition string',
  }

Returns undef on failure.

=head2 $deck->card_side($n, $side)

Returns side $side of card $n. $side must be 'Term' or 'Definition'
(case-sensitive).

=head2 $deck->order_deck([$side])

Order cards alphabetically by $side, which must be 'Term' or 'Definition'
(case-sensitive). If $side is not specified, sorts by terms.

=head2 $deck->shuffle_deck()

Randomize order of cards.

=head1 AUTHOR

Written by Samuel Young E<lt>L<samyoung12788@gmail.com>E<gt>.

=head1 COPYRIGHT

Copyright 2024, Samuel Young

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<tarotplane>

=cut
