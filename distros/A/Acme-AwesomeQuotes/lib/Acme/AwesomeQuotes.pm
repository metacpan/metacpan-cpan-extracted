use strict;
use warnings;
use utf8;
use 5.008_003;

package Acme::AwesomeQuotes;
BEGIN {
  $Acme::AwesomeQuotes::VERSION = '0.02';
}

binmode STDIN,  ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(GetAwesome);
our @EXPORT    = qw(GetAwesome);

use Carp qw(croak);
use Unicode::Normalize qw(NFC NFD);

# ABSTRACT: Make your text awesome!


my %chartypes = (
                 'all'      => qr/[\x{030C}\x{0300}\x{0301}]/,
                 'notgrave' => qr/[^\P{NonspacingMark}\x{0300}]/,
                 'notacute' => qr/[^\P{NonspacingMark}\x{0301}]/,
                 'notcaron' => qr/[^\P{NonspacingMark}\x{030C}]/,
                 'puncsep'  => qr/[\p{Separator}\p{Punctuation}]/,
                );


sub GetAwesome {
	(my $string = NFD($_[0])) =~ s/(?:^${chartypes{puncsep}}+|${chartypes{puncsep}}+$)//g;

	eval {checkstring($string)} or croak $@;

	# For individual characters, use a caron instead of terminal acute/grave accents:
	if ($string =~ /^\p{Letter}\p{NonspacingMark}*$/) {
		# Prep string – remove extant carons/accents:
		$string =~ s/^(\p{Letter}${chartypes{notcaron}}*)${chartypes{all}}+(${chartypes{notcaron}}*)$/$1$2/;

		# Make string awesome!
		$string = NFC($string);
		$string =~ s/^(.*)$/`$1\x{030C}´/;
	}
	else {
		# If there are initial acute/terminal grave accents, use a caron instead:
		my $initialaccent = ($string =~ s/^(\p{Letter}\p{NonspacingMark}*)[\x{0301}\x{030C}]+/${1}/g)
		  ? "\x{030C}" : "\x{0300}";
		my $finalaccent   = ($string =~ s/(\p{Letter}\p{NonspacingMark}*)[\x{0300}\x{030C}]+(\p{NonspacingMark}*)$/${1}${2}/g)
		  ? "\x{030C}" : "\x{0301}";

		# Prep string – remove extant terminal acute/grave accents:
		$string =~ s/^(\p{Letter}${chartypes{notgrave}}*)\x{0300}/$1/;
		$string =~ s/(\p{Letter}${chartypes{notacute}}*)\x{0301}(${chartypes{notacute}}*)$/$1$2/;

		# Make string awesome!
		$string = NFC($string);
		$string =~ s/^(\p{Letter}\p{ModifierLetter}*)/`${1}${initialaccent}/;
		$string =~ s/(\p{Letter}\p{ModifierLetter}*)$/${1}${finalaccent}´/;
	}

	return(NFC($string));
}


sub checkstring {
	my $string = $_[0];
	if ($string eq '') {
		die "String is empty!\n";
	}
	elsif ((($string =~ /^`\p{Letter}${chartypes{notgrave}}*\x{0300}/) &&
	        ($string =~ /\p{Letter}${chartypes{notacute}}*\x{0301}${chartypes{notacute}}*´$/)) ||
	       ($string =~ /^`\p{Letter}${chartypes{notcaron}}*\x{030C}${chartypes{notcaron}}*´$/)) {
		die "String '$string' is *already* awesome!\n";
	}
	elsif ($string !~ /^\p{Letter}/) {
		die "String '$string' begins with a non-letter character.\n";
	}
	elsif ($string !~ /\p{Letter}\p{NonspacingMark}*$/) {
		die "String '$string' terminates with a non-letter character.\n";
	}
	else {
		1;
	}
}


1; # This is a module, so it must return true.

__END__
=pod

=encoding utf-8

=head1 NAME

Acme::AwesomeQuotes - Make your text awesome!

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Acme::AwesomeQuotes;
  my $awesome_text = GetAwesome('Wyld Stallyns');
  say q(I'm Bill S. Preston, Esquire!);
  say q(And I'm Ted "Theodore" Logan!);
  say ('And we are ', $awesome_text, '!');

=head1 DESCRIPTION

Tired of ordinary quotation marks that lack punch?

Looking for something that can better convey just how I<awesome> your words are?

You need `àwesome quoteś´!

=head1 FUNCTIONS

=head2 GetAwesome

C<GetAwesome()> is the module’s only function, and is exported by default. It takes a single scalar string argument, and returns that string with the following changes applied:

=over 4

=item *

a grave accent (or backtick, U+0060) is prepended;

=item *

a combining grave accent is added to the first letter;

=item *

a combining acute accent is added to the final letter;

=item *

an acute accent (U+00B4) is appended;

=back

In addition, leading/trailing whitespace and punctuation is stripped, and the returned string is in NFC.

Combining characters already present in the string are respected, and existing initial/terminal grave/acute accents will not be doubled.  However, in cases where both a grave and acute accent may be applied – such as if the initial letter has an acute accent, or if the string consists of only a single letter – a caron is used instead, because combining grave and acute accents on the same character doesn’t look so hot. :)

=for Pod::Coverage checkstring

=head1 LIMITATIONS

=over 4

=item *

N.B. that the first and last characters of the supplied string must be I<letters>; leading/trailing whitespace and punctuation will be stripped, and if the resulting first/last character is not a letter an exception will be raised.  Letters may be from any script covered by Unicode.  Because leading/trailing punctuation is stripped, if your text is to go e.g. at the end of a sentence, you should apply the full-stop I<after> calling C<GetAwesome()>.

=item *

The returned string is in NFC; combining accents will therefore occur as separate characters only if there is no code point for the corresponding character+accent.

=item *

A string that is already in `àwesome quoteś´ cannot be made I<more> awesome by calling the function on it repeatedly. :)

=back

=head1 BUGS

None known, doubtless many undiscovered.

=head1 SEE ALSO

Acme::LeetSpeak L<http://search.cpan.org/~jmadler/Acme-LeetSpeak-0.01/lib/Acme/LeetSpeak.pm>

=head1 ACKNOWLEDGEMENTS

Thanks to the regulars on L<irc://irc.perl.org/perl> for the idea.  Thanks to Ævar Arnfjörð Bjarmason (avar, L<http://search.cpan.org/~avar/>) for helpful suggestions on packaging.

=head1 AUTHOR

Marcus Smith <carwash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcus Smith.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

