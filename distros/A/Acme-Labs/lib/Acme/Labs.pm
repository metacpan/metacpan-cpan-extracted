package Acme::Labs;

our $VERSION = '1.1';	# September 14, 2005


srand; rand($.) < 1 && (our $but = $_) while <DATA>; chomp $but;				# randomly choose a line of DATA
our $Qyes; our $yEs="I think so, Brain";
our $pondering = qq(BRAIN:\t"Pinky, are you pondering what I'm pondering?"\nPINKY:\t"$yEs, $but"\n\n);

my @interjections=qw(NARF POIT ZORT EGAD);
my $interjections=join("|", @interjections);									# OR'd list for regexes

our (%zord, %chroz);
my $c=ord("A"); foreach my $w (@interjections) {my $l=length $w; for(my $n=0; $n<2**$l; $n++) {my $narf; my $b=unpack("b$l", chr $n); for my $i (0..$l-1) { $narf.=substr($b, $i, 1)?lc substr($w, $i, 1):uc substr($w, $i, 1); } $chroz{$narf}=chr($c); $zord{chr($c++)}=$narf;}}

#----------------------------------------------------------------------

sub AYPWIP 
{
	local $pondering="\Q$pondering\E"; 
	local $yEs="\Q$yEs\E";
	local $Qyes="\Q$yEs\E";

	$pondering=~s[$Qyes.*\s*][$yEs]s;
	$_[0] =~ /^\s*$pondering/ 
}

sub pinking
{
	local $_=pop;
	s/([A-Z])/ $zord{$1}/ig;
	"\n\n$pondering$_"
}

sub brainier
{
	local $_ = pop;

	local $pondering="\Q$pondering\E"; 
	local $yEs="\Q$yEs\E";
	local $Qyes="\Q$yEs\E";

	$pondering=~s[$Qyes.*][$yEs]s;

	s/^\s*$pondering.*\n\n//;	
	s/^\n//;
	s/ ($interjections)/$chroz{$1}/ig;
	$_
}

#----------------------------------------------------------------------

open 0 or print "NARF?  What does that mean?!? '$0'\n" and exit;				# read our source code

(my $plan = join "", <0>) =~ s[(.*^\s*use\s+Acme::Labs\s*;)]["\n" x (split /\n/, $1)]mes;	# capture intro for preserving later on (and leave behind the same number of \n's so we don't throw off the line numbers)

do {eval brainier $plan or print STDERR $@; exit} if AYPWIP($plan);				# if we recognise a Pinky's Plan, apply to North Pole, I mean, Brain

open 0, ">$0" or print "Cannot get pinking shears! '$0'\n" and exit;			# Otherwise, prepare to pinkify!
print {0} $1, pinking $plan 													# write out reformulated plan
	and print STDOUT "Fun-fun-silly-willy!\n" 
		and do {eval brainier $plan or print STDERR $@; exit};					# and execute our plan

#----------------------------------------------------------------------

=pod

=head1 NAME

Acme::Labs -- When you need an extraordinary plan to Take Over the World


=head1 SYNOPSIS

	use Acme::Labs;
	
	print "Egad, brilliant, Brain!\n";
	print "Oh, wait, no -- it'll never work!";


=head1 DESCRIPTION

When you run a program under C<use Acme::Labs>, the module replaces all the 
big, complicated words in your source file. The code will still work the way it 
used to, but it will look something like this:

	use Acme::Labs;
	
	BRAIN:	"Are you pondering what I'm pondering?"
	PINKY:	"I think so, Brain, but where will we find a duck and a hose at this time of night?"
	
	
	 zort eGAD ZORt zOrt egAD " NArF ZorT ZORT zoRT,  zORT eGAD ZORt zoRt zoRt ZORt ZORT zOrt egAD,  nARF eGAD ZORT ZORt zOrt!\ zOrt";
	 zort eGAD ZORt zOrt egAD " Narf zorT,  EgaD ZORT ZORt egAD,  zOrt Zort --  ZORt egAD' zoRt zoRt  zOrt ZOrT eGaD ZOrT eGAD  EgaD Zort eGAD ZoRt!";


=head1 DIAGNOSTICS

=over 4

=item C<Fun-fun-silly-willy!>

Acme::Labs has done its work on your script.  (Only appears the first time
you run under Acme::Labs, to indicate that the source code has been
translated successfully[sic].)

=item C<NARF? What does that mean?!? '%s'>

Acme::Labs could not read the source file.

=item C<Cannot get pinking shears '%s'>

Acme::Labs could not modify the source file.

=back

=head1 BUGS

There's no (easy) way to recover the original script.
(If you're going to let Pinky mess with your work, that's about what you should 
expect.)

The C<use> of Acme::Labs pretty much has to be the first line in the source
code.  (Well, before any run-time stuff, or something like that.)  It should
also be the only statement on its line.

There are probably other bugs not documented in this section.  (Unless you
count the indirect mention in the previous sentence, in which case it's not
a bug that they aren't mentioned because they are. And so saying that this
was a bug is in fact a bug itself.  Whether the bug of saying bugs aren't
mentioned when really they are is covered by the indirect mentioning of the
aforementioned bugs is left as an exercise for Bertrand Russell.)


=head1 SEE ALSO

L<Acme::Bleach>, L<http://www.animaniacs.info>, your psychiatrist


=head1 AUTHOR

David Green, C<< <plato@cpan.org> >>, with apologies to Damian Conway (or vice versa).


=head1 COPYRIGHT

Copyright (c) 2003, David Green. This module is free software: It may be used, 
redistributed, or modified under the terms of the Perl Artistic License
(L<http://www.perl.com/perl/misc/Artistic.html>).

=cut

#----------------------------------------------------------------------

__DATA__
but if you replace the 'P' with an 'O', my name would be 'Oinky', wouldn't it?
but don't camels spit a lot?
but 'Snowball for Windows'?
but I don't think Kay Ballard's in the union.
but I find scratching just makes it worse.
but Pete Rose?  I mean, can we trust him?
but Tuesday Weld isn't a complete sentence!
but Zero Mostel times anything will still give you Zero Mostel!
but calling it pu-pu platter?  Huh, what were they thinking!
but can the Gummi Worms really live in peace with the Marshmallow Chicks?
but culottes have a tendency to ride up so.
but don't you need a swimming pool to play Marco Polo?
but how will we get a pair of Abe Vigoda's pants?
but how will we get the Spice Girls into the paella?
but if it was only supposed to be a three hour tour, why did the Howells bring all their money?
but if the plural of 'mouse' is 'mice', wouldn't the plural of 'spouse' be 'spice'?
but if they called them "Sad Meals", kids wouldn't buy them!
but if we get Sam Spade, we'll never have any puppies!
but if we give peas a chance, won't the lima beans feel left out?
but if we had a snowmobile, wouldn't it melt before summer?
but if we have nothing to fear but fear itself, why does Eleanor Roosevelt wear that spooky mask?
but isn't a cucumber that small called a gherkin?
but isn't that why they invented tube socks?
but just how will we get the weasel to hold still?
but me and Pippi Longstocking -- I mean, what would the children look like?
but pants with horizontal stripes make me look chubby.
but shouldn't the bat boy be wearing a cape?
but then I would have to know what 'pondering' is, wouldn't I?"
but then my name would be 'Thumby'.
but there's still a bug stuck in here from last time!
but this time you put the trousers on the chimp!
but three round meals a day wouldn't be as hard to swallow.
but we're already naked!
but what if the hippopotamus won't wear the beach thong?
but what kind of rides do they have in Fabioland?
but where are we going to find a duck and a hose at this hour?
but why does a forklift have to be so big if all it does is lift forks?
but why would Peter Bogdanovich?
but why would anyone want a depressed tongue?
but why would anyone want to see Snow White and the Seven Samurai?
but wouldn't his movies be more suitable for children if he was named Jean-Claude van Darn?
but, the Rockettes?  I mean, it's mostly girls, isn't it?
but, uh...something about a duck...
but where will we find an open tattoo parlor at this time of night?
but I think I'd rather eat the Macarena.
but how are we going to find chaps our size?
but this time, you wear the tutu.
but I get all clammy inside the tent.
but balancing a family and a career ... ooh, it's all too much for me!
but we'll never get a monkey to use dental floss!
but where are we going to find rubber pants our size?
but a show about two talking lab mice?  Hoo!  It'll never get on the air!
but why would anyone want to Pierce Brosnan?
but three men in a tub?  Ooh, that's unsanitary!
but what if the chicken won't wear the nylons?
but, umm, why would Sophia Loren do a musical?
but Kevin Costner with an English accent?
but what if we stick to the seat covers?
but 'apply North Pole' to what?
but <snort> no, no, it's too stupid!
but I can't memorize a whole opera in Yiddish!
but do I really need two tongues?
but first you'd have to take that whole bridge apart, wouldn't you?
but if Jimmy cracks corn, and no one cares, why does he keep doing it?
but it's a miracle that this one grew back!
but pantyhose are so uncomfortable in the summertime!
but where do you stick the feather and call it macaroni?
but I prefer Space Jelly!
but burlap chafes me so!
but how will we get three pink flamingos into one pair of Capri pants?
but if we didn't have ears, we'd look like weasels.
but isn't Regis Philbin already married?
but will they let the Cranberry Duchess stay in the Lincoln Bedroom?
but wouldn't anything lose its flavor on the bedpost overnight?
but if our knees bent the other way, how would we ride a bicycle?