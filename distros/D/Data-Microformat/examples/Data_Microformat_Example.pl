use strict;

use Data::Microformat::hCard;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $res = $ua->get("http://ussjoin.com/");
my $card = Data::Microformat::hCard->parse($res->content);

print "The full name we found in this hCard was:\n";
print $card->n->to_text."\n";

# To create a new hCard:
my $new_card = Data::Microformat::hCard->new;
$new_card->fn("Brendan O'Connor");
$new_card->nickname("USSJoin");

my $new_email = Data::Microformat::hCard::type->new;
$new_email->kind("email");
$new_email->type("Perl");
$new_email->value('perl@ussjoin.com');
$new_card->email($new_email);

print "Here's the new hCard I've just made:\n";
print $new_card->to_hcard."\n";

print "Here's a more easily human-readable version:\n";
print $new_card->to_text."\n";