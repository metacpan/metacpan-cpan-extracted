
package Biblio::SICI::Util;
{
  $Biblio::SICI::Util::VERSION = '0.04';
}

# ABSTRACT: Utility functions

use strict;
use warnings;
use 5.010001;

BEGIN {
	$Biblio::SICI::Util::TITLE_CODE = qr/[0-9A-Z&´*\\\{\}\(\)\[\],\@\$=!#%.+?";\/^\`~_|-]/;
}

use Exporter 'import';
our @EXPORT_OK = qw( calculate_check_char titleCode_from_title );

use Try::Tiny;


sub titleCode_from_title {
	my $title = shift;

	die "Expected title string as parameter" unless defined($title) and $title;

	my $code = '';

	try {
		require Text::Unidecode;
	}
	catch {
		warn __PACKAGE__ . "::titleCode_from_title() - unable to load 'Text::Unidecode': " . $_;
	};

	try {
		require Text::Undiacritic;
	}
	catch {
		warn __PACKAGE__ . "::titleCode_from_title() - unable to load 'Text::Undiacritic': " . $_;
	};

	my @words = split( /\s+/, $title );
	my @chars = ();
	foreach my $word (@words) {
		my $firstChar = uc( substr( $word, 0, 1 ) );
		if ( $firstChar =~ $Biblio::SICI::Util::TITLE_CODE ) {
			push @chars, $firstChar;
		}
		else {
			try {
				$word = Text::Unidecode::unidecode($word);
			};
			try {
				$word = Text::Undiacritic::undiacritic($word);
			};
			$firstChar = uc( substr( $word, 0, 1 ) );
			if ( $firstChar =~ $Biblio::SICI::Util::TITLE_CODE ) {
				push @chars, $firstChar;
			}
		}
	}

	if ( @chars >= 1 ) {
		$code = join( "", splice( @chars, 0, 6 ) );
		return $code;
	}

	return;
} ## end sub titleCode_from_title


sub calculate_check_char {
	my $str = shift;

	return unless defined($str) and $str;

	state $charValues = {
		0 => 0,  1 => 1,  2 => 2,  3 => 3,  4   => 4,  5 => 5,  6 => 6,  7 => 7,
		8 => 8,  9 => 9,  A => 10, B => 11, C   => 12, D => 13, E => 14, F => 15,
		G => 16, H => 17, I => 18, J => 19, K   => 20, L => 21, M => 22, N => 23,
		O => 24, P => 25, Q => 26, R => 27, S   => 28, T => 29, U => 30, V => 31,
		W => 32, X => 33, Y => 34, Z => 35, '#' => 36
	};

	state $valueToChar = { reverse %{$charValues} };

	$str =~ s/\-[0-9A-Z#]\Z/-/o;    # remove check char if present

	my @chars  = split( //, $str );
	my @mapped = ();
	my $i      = 0;
	foreach my $c (@chars) {
		if ( exists $charValues->{$c} ) {
			$mapped[$i] = $charValues->{$c};
		}
		else {
			$mapped[$i] = 36;
		}
		$i++;
	}

	my $sum = 0;
	for ( my $j = $#mapped; $j >= 0; $j -= 2 ) {
		$sum += $mapped[$j];
	}

	$sum *= 3;

	for ( my $j = $#mapped - 1; $j >= 0; $j -= 2 ) {
		$sum += $mapped[$j];
	}

	my $mod = $sum % 37;

	# if remainder == 0; then 0 is the check char
	return '0' if $mod == 0;

	my $checkVal  = 37 - $mod;
	my $checkChar = $valueToChar->{$checkVal};

	return $checkChar;
} ## end sub calculate_check_char


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Biblio::SICI::Util - Utility functions

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Biblio::Sici;
  use Biblio::SICI::Util qw( titleCode_from_title calculate_check_char );

  my $sici = Biblio::Sici->new();

  ...

  if ( my $code = titleCode_from_title($title) ) {
      $sici->contribution->titleCode($code);
  }

=head1 DESCRIPTION

This module provides some utility functions which are useful when
working with SICI.

None of them are exported by default.

=head1 FUNCTIONS

=over 4

=item STRING C<titleCode_from_title>( STRING )

Tries to derive the C<titleCode> (cf. the contribution segment) 
from a string (i.e.: the title of the contribution) passed to it. 

Since the rules for the construction of the C<titleCode> are
quite complex, this method probably won´t generate the correct
code if the title contains elements other than regular english 
words (like mathematical or chemical symbols or characters from
a non-ascii alphabet).

If the method is able to generate a code it will be returned.
Otherwise the return value is C<undef>.

In order to have a better chance of generating a standard-conformant 
code the modules L<Text::Unidecode> and L<Text::Undiacritic> are 
C<require>d.
If they cannot be found, warnings are emitted but a code
might nonetheless be generated. However, if the title is in
a language other than english, the probability of generating
the correct code sinks even more.

=item STRING C<calculate_check_char>( STRING )

Calculates and returns the check character.
Does B<not> check, if the string param is a valid SICI! 

A check character already present in the passed-in SICI will
simply be ignored.

=back

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
