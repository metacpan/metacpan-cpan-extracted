package App::Tarotplane::Cards;
use 5.016;
use strict;
use warnings;

use Carp;
use List::Util qw(shuffle);

sub new {

	my $class = shift;
	my @files = @_;

	my $self = {
		Cards   => [],
		CardNum => 0,
	};

	foreach my $f (@files) {

		my $lnum = 0;
		my $origtotal = $self->{CardNum};

		open my $fh, '<', $f or croak "Could not open $f: $!";

		while (my $l = readline $fh) {

			$lnum++;

			# Skip comments and blanks
			my $first = substr $l, 0, 1;
			next if $first eq '#' or $first eq "\n";

			chomp $l;

			# Add null byte so that subsequent substitutions will not interfere
			# with '\\' back slash.
			$l =~ s/\\\\/\\\0/g;

			# Line must contain non-escaped colon
			if ($l !~ /[^\\]:/) {
				close $fh;
				croak "$f: Bad line at $lnum, does not contain delimiting colon";
			}

			my (undef, $term, $def) = split(/(^.*[^\\]):/, $l, 2);

			## Now interpret escape codes
			# '\:' -> ':'
			$term =~ s/\\:/:/g;
			$def  =~ s/\\:/:/g;

			# '\n' -> line break
			$term =~ s/\\n/\n/g;
			$def  =~ s/\\n/\n/g;

			# No longer need '\\' substitution null byte
			$term =~ s/\0//g;
			$def  =~ s/\0//g;

			# Trim
			$term =~ s/^\s+|\s+$//g;
			$def  =~ s/^\s+|\s+$//g;

			push @{$self->{Cards}}, {
				'Term'       => $term,
				'Definition' => $def,
			};

			$self->{CardNum}++;

		}

		close $fh;

		if ($origtotal == $self->{CardNum}) {
			croak "No cards found in $f";
		}

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

Reads cards from @files, and returns an App::Tarotplane::Cards object.

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
