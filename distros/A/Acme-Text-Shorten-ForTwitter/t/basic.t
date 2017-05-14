use strict;
use warnings;

use Test::More;
use Acme::Text::Shorten::ForTwitter;

# Some basics, also texting happens before contractions
my $shortener = Acme::Text::Shorten::ForTwitter->new;
my $short = $shortener->shorten("I will not, do not, say you are, why?");
is($short, "I won't, don't, say ur, y?", 'shortened correctly');

Acme::Text::Shorten::ForTwitter->import('-texting');
$shortener = Acme::Text::Shorten::ForTwitter->new;
$short = $shortener->shorten("I will not, do not, say you are, why?");
is($short, "I won't, don't, say you're, why?", 'shortened correctly with -texting');

Acme::Text::Shorten::ForTwitter->import('+texting');
$shortener = Acme::Text::Shorten::ForTwitter->new;
$short = $shortener->shorten("I will not, do not, say you are, why?");
is($short, "I will not, do not, say ur, y?", 'shortened correctly with +texting');

# Make sure longer contractions are used first
Acme::Text::Shorten::ForTwitter->import('+contractions');
$shortener = Acme::Text::Shorten::ForTwitter->new;
$short = $shortener->shorten("I would have");
is($short, "I'd've", 'shortened correctly with +contractions (longer words used)');

done_testing;
