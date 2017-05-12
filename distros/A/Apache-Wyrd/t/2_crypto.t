use Apache::Wyrd::Services::SAK qw(:all);
use Apache::Wyrd::Services::CodeRing;

my $count = &count;

print "1..$count\n";

#my $time = time;
my $cr = Apache::Wyrd::Services::CodeRing->new;
#warn time - $time . " seconds to initialize CodeRing\n";

my $short_string = 'yahoo!';
my $long_string = <<'__STRING__';
  There was nothing so VERY remarkable in that; nor did Alice
think it so VERY much out of the way to hear the Rabbit say to
itself, `Oh dear!  Oh dear!  I shall be late!'  (when she thought
it over afterwards, it occurred to her that she ought to have
wondered at this, but at the time it all seemed quite natural);
but when the Rabbit actually TOOK A WATCH OUT OF ITS WAISTCOAT-
POCKET, and looked at it, and then hurried on, Alice started to
her feet, for it flashed across her mind that she had never
before seen a rabbit with either a waistcoat-pocket, or a watch to
take out of it, and burning with curiosity, she ran across the
field after it, and fortunately was just in time to see it pop
down a large rabbit-hole under the hedge.

  In another moment down went Alice after it, never once
considering how in the world she was to get out again.

  The rabbit-hole went straight on like a tunnel for some way,
and then dipped suddenly down, so suddenly that Alice had not a
moment to think about stopping herself before she found herself
falling down a very deep well.

  Either the well was very deep, or she fell very slowly, for she
had plenty of time as she went down to look about her and to
wonder what was going to happen next.  First, she tried to look
down and make out what she was coming to, but it was too dark to
see anything; then she looked at the sides of the well, and
noticed that they were filled with cupboards and book-shelves;
here and there she saw maps and pictures hung upon pegs.  She
took down a jar from one of the shelves as she passed; it was
labelled `ORANGE MARMALADE', but to her great disappointment it
was empty:  she did not like to drop the jar for fear of killing
somebody, so managed to put it into one of the cupboards as she
fell past it.

  `Well!' thought Alice to herself, `after such a fall as this, I
shall think nothing of tumbling down stairs!  How brave they'll
all think me at home!  Why, I wouldn't say anything about it,
even if I fell off the top of the house!' (Which was very likely
true.)

  Down, down, down.  Would the fall NEVER come to an end!  `I
wonder how many miles I've fallen by this time?' she said aloud.
`I must be getting somewhere near the centre of the earth.  Let
me see:  that would be four thousand miles down, I think--' (for,
you see, Alice had learnt several things of this sort in her
lessons in the schoolroom, and though this was not a VERY good
opportunity for showing off her knowledge, as there was no one to
listen to her, still it was good practice to say it over) `--yes,
that's about the right distance--but then I wonder what Latitude
or Longitude I've got to?'  (Alice had no idea what Latitude was,
or Longitude either, but thought they were nice grand words to
say.)

  Presently she began again.  `I wonder if I shall fall right
THROUGH the earth!  How funny it'll seem to come out among the
people that walk with their heads downward!  The Antipathies, I
think--' (she was rather glad there WAS no one listening, this
time, as it didn't sound at all the right word) `--but I shall
have to ask them what the name of the country is, you know.
Please, Ma'am, is this New Zealand or Australia?' (and she tried
to curtsey as she spoke--fancy CURTSEYING as you're falling
through the air!  Do you think you could manage it?)  `And what
an ignorant little girl she'll think me for asking!  No, it'll
never do to ask:  perhaps I shall see it written up somewhere.'
__STRING__

my $short_random_string = random_string(7);
my $long_random_string = random_string(20000);

my $time = time;
my $cryptstring = $cr->encrypt(\$short_string);
my $plainstring = $cr->decrypt($cryptstring);

print "not " if ($short_string ne $$plainstring);
print "ok 1 - short regular encoding\n";

$cryptstring = $cr->encrypt(\$short_random_string);
$plainstring = $cr->decrypt($cryptstring);

print "not " if ($short_random_string ne $$plainstring);
print "ok 2 - short random encoding\n";

$cryptstring = $cr->encrypt(\$long_string);
$plainstring = $cr->decrypt($cryptstring);

print "not " if ($long_string ne $$plainstring);
print "ok 3 - long encoding\n";
#compare(\$long_string, $plainstring) if ($long_string ne $$plainstring);

$cryptstring = $cr->encrypt(\$long_random_string);
my $cryptcryptstring = $cr->encrypt($cryptstring);
my $cryptplainstring = $cr->decrypt($cryptcryptstring);
$plainstring = $cr->decrypt($cryptstring);

print "not " if ($long_random_string ne $$plainstring);
print "ok 4 - long random encoding\n";
#compare(\$long_random_string, $plainstring) if ($long_random_string ne $$plainstring);
#warn time - $time . " seconds to run CodeRing tests\n";


sub count {4}

sub compare {
	my ($original, $teststring) = @_;
	my $counter;
	my @compare = split '', $$original;
	my @char = split '', $$teststring;
	foreach my $char (@char) {
		$counter++;
		my $compare = shift @compare;
		print "$counter: '$char' eq '$compare'\n";
		die "strings differ at char # $counter: '$char' ne '$compare'\n" if ($char ne $compare);
	}
}

sub random_string {
	my $size = shift;
	my $string = undef;
	for (my $i=0; $i<$size; $i++) {
		$string .= chr(rand(256)) ;
	}
	return $string;
}
