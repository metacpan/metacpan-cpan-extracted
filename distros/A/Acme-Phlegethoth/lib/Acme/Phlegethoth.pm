package Acme::Phlegethoth;

use warnings;
use strict;

our $VERSION  = '1.05';
my $hear_me   = "ia ia! ";
my $amen      = " [Text ends abruptly.]\n";
my @pre       = qw( c f' h' na nafl ng nnn ph' y );
my @suf       = qw( agl nyth og or oth yar );
my @word      = qw(
	ah 'ai athg 'bthnk bug ch' chtenff ebumna ee ehye ep 'fhalma fhtagn
	fm'latgh ftaghu geb gnaiih gof'nn goka gotha grah'n hafh'drn hai
	hlirgh hrii hupadgh ilyaa k'yarnak kadishtu kn'a li'hee llll lloig
	lw'nafh mg mnahn' n'gha n'ghft nglui nilgh'ri nog nw ooboshu orr'e
	phlegeth r'luh ron s'uhn sgn'wahl shagg shogg shtunggli shugg sll'ha
	stell'bsna syha'n tharanak throd uaaah uh'e uln vulgtlagln vulgtm
	wgah'n y'hah ya zhro
);

sub summon {
	my $old_one = unpack "b*", shift;
	my $prayer  = $hear_me;
	my $chant   = "";

	foreach my $tentacle (split //, $old_one) {
		$chant = reverse(
			((rand() < 0.25) ? $pre[rand @pre] : "") .
			$word[rand @word] .
			((rand() < 0.25) ? $suf[rand @suf] : "") .
			((rand() < 0.1) ? "! " : "") .
			" "
		) unless length $chant;
		$prayer .= $1, redo if $chant =~ s/([^a-z])$//;
		$prayer .= chop $chant;
		substr($prayer, -1, 1) =~ tr[a-z][A-Z] if $tentacle;
	}

	$prayer .= $amen;
}

sub banish {
	local $_ = shift;
	s/^\Q$hear_me//; s/\Q$amen\E$//; tr[a-zA-Z][]cd; tr[a-z][0]; tr[A-Z][1];
	pack "b*", $_;
}

sub see { $_[0] =~ /\S/ }
sub comprehend { $_[0] =~ /^\Q$hear_me/ }
sub roll_sanity_check { &see }

sub import {
	no strict 'refs';
	open 0 or warn "Can't summon '$0'\n" and exit;
	(my $old1 = join "", <0>) =~ (
		s/(.*^\s*)use\s+Acme('|::)Phlegethoth\s*;\s*\n//sm
	);
	my $harbinger = $1 || "";
	local $SIG{__WARN__} = \&roll_sanity_check;
	do {eval banish $old1; exit} unless see $old1 and not comprehend $old1;
	open 0, ">$0" or warn "Can't banish '$0'\n" and exit;
	print {0} "${harbinger}use Acme'Phlegethoth;\n", summon $old1 and exit;
	print "${harbinger}use Acme'Phlegethoth;\n", summon $old1 and exit;
}

__END__

=head1 NAME

Acme::Phlegethoth - Improve your code's readability, if you're an Ancient One

=head1 SYNOPSIS

	use Acme::Phlegethoth;
	print "goodbye, world!\n";

=head1 DESCRIPTION

Acme::Phlegethoth improves the readability of your Perl programs to
the Elder Gods.  This may accelerate a debugging session where you
feel compelled to invoke them.  After all, if you're outsourcing
development to Cthulhu, you'd better damn well be sure He can read
your code.

Acme::Phlegethoth translates your code to Aklo the first time your
program uses it.  From that point on, your program continues to work
as before, but it now looks something like this:

	use Acme'Phlegethoth;
	ia ia!  mnahN' NAflHriI R'LuHnyTh BUgoR SLl'HAog gOf'NN Hai ron
	gOf'nn Nnn'aIog FHTagN LlLL YHlIRgHOG GoF'Nn naCh'!  nNNvuLgtlAGlN
	thROD!  PhLeGetH StelL'BsNaoth sll'Ha!  aH NAfL'AIyAR H'EbUMna
	HliRGHog eHYeOG nnnSgn'WAhL fm'laTgh ah ILYaA h'zHRO iLYaa
	H'gnaIihNYtH EBumnA s'Uhnor [Text ends abruptly.]

which loosely translates to:

	Hear me!

	Call upon the cowardly servants of the unbelievers!  Invite them to
	into our Church!  Watch over them, protect them!  These heretic
	children will enter the beyond to sleep beside our Master!

	Prepare us for the time when the Servants of your Father rise from
	the Pit to fulfil his pact.

	Our unshaken belief will protect our place on Earth!

	[Text ends abruptly.]

=head1 DIAGNOSTICS

=over 4

=item C<Can't summon '%s'>

Acme::Phlegethoth could not access your code to translate it into
Aklo.  The Ancient Ones will be most displeased.

=item C<Can't banish '%s'>

Acme::Phlegethoth could not access your prayer to execute it.  Never
let this happen.  The Sleeping Ones do not like to be awakened without
reason.

=head1 AUTHOR

Rocco Caputo <rcaputo@cpan.org>

This was loosely based on Leon Brocard's Acme::Buffy, which in turn
was based on Damian Conway's Bleach module.  That was inspired by an
idea by Philip Newton.  By now there's enough blame for everyone.

But what really sparked my imagination was Meng Weng Wong's quote from
a couple Ruby users:

	<flippo> ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn!
	<ibroadfo> flippo: don't paste perl in here

They will of course be eaten last.

=head1 LINKS

=head2 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Queue=Acme-Phlegethoth

=head2 REPOSITORY

http://github.com/rcaputo/acme-phlegethoth

=head2 OTHER RESOURCES

http://search.cpan.org/dist/Acme-Phlegethoth/

=head1 COPYRIGHT

Copyright (c) 2006-2009, Rocco Caputo.  All Rights Reserved.  This
module is free software.  It may be used, redistributed and/or
modified under the same terms as Perl itself.

Thanks to the "Cthuvian / English Dictionary" for providing the
lexicon and translations in one convenient place.

=cut
