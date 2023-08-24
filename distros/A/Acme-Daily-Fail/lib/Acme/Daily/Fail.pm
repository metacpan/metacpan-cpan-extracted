package Acme::Daily::Fail;
$Acme::Daily::Fail::VERSION = '1.22';
#ABSTRACT: generate random newspaper headlines

use strict;
use warnings;
use Math::Random;

our @ISA            = qw[Exporter];
our @EXPORT_OK      = qw[get_headline];

use constant PLURAL => 0;
use constant SINGULAR => 1;
use constant TENSE => 2;

use constant WORD => 0;
use constant PERSON => 1;
use constant NUMBER => 2;

use constant PRESENT => 0;
use constant PAST => 1;
use constant ACTIVE => 2;
use constant OBJECT => 3;

sub _getRandom {
  my $array = shift || return;
  return $array->[ scalar random_uniform_integer(1,0,$#{ $array }) ];
}

# Auxiliary verbs (the first word in the sentence)
#function Verb(plural, singular, tense) {

my $auxiliary_verbs = [
	["will", "will", "present"],
	["could", "could", "present"],
	["are", "is", "active"],
	["have", "has", "past"]
];

# Subjects (i.e. bad things)
#function Noun(word,person,number) {

my $subjects = [
	["the labour party",3,1],
	["brussels",3,1],
	["the bbc",3,1],
	["the e.u.",3,1],
	["the euro",3,1],
	["the loony left",3,1],
	["the unions",3,2],       # May be a bit quaint this one
	["channel 4",3,1],
	["your local council",3,1],
	["the french",3,2],
	["the germans",3,2],
	["the poles",3,2],
	["brussels bureaucrats",3,2],
	["muslims",3,2],
	["immigrants",3,2],        # Except those from the UK to Spain & the Algarve of course
	["teachers",3,2],
	["the unemployed",3,2],
	["gypsies",3,2],
	["yobs",3,2],
	["hoodies",3,2],
	["feral children",3,2],    # They hate children *and* paedophiles FFS, make your minds up
	["chavs",3,2],
	["the p.c. brigade",3,2],
  ["cyclists",3,2],
	["asylum seekers",3,2],    # Nicer way of saying 'brown people'
	["gays",3,2],
	["lesbians",3,2],
	["single mothers",3,2],
	["working mothers",3,2],
	["paedophiles",3,2],
	["teenage sex",3,1],
	["political correctness",3,1],
	["health & safety",3,1],
	["feminism",3,1],
	["the metric system",3,1],    # For fuck's sake
	["dumbing-down",3,1],
	["rip-off britain",3,1],
	["the internet",3,1],
	["facebook",3,1],             # I CAN'T BELIEVE THE MAIL ACTUALLY SAID FACEBOOK COULD GIVE YOU CANCER, FOR REAL
	["filth on television",3,1],
	["the human rights act",3,1],
	["the nanny state",3,1],
	["cancer",3,1],               # Could cancer give you cancer?
	["binge drinking",3,1],
	["the house price crash",3,1],# Hahahaha
	["jihadists",3,2],             # Topical
	["x factor",3,1],             # Topical
	["foxes",3,2],
	["twitter",3,1],            # Topical
	["the mmr jab",3,1],             # Topical
  ["judges",3,2],
  ["covid",3,1],              # fuck you, 2020
  ['meghan markle',3,1],
  ['woke',3,1],
];

# Transitive phrases (i.e. bad thing they do)
#function Phrase(present, past, active, object) {

my $transitive_phrases = [
	["give", "given", "giving", "cancer"],
	["give", "given", "giving", "cancer"], # Have it twice as they're so bloody obsessed by it
	["give", "given", "giving", "covid"],
	["infect", "infected", "infecting", "with AIDS"],
	["make", "made", "making", "obese"],
	["give", "given", "giving", "diabetes"],
	["make", "made", "making", "impotent"],
	["turn","turned","turning","gay"],
	["scrounge off","scrounged off","scrounging off",""],
	["tax", "taxed", "taxing", ""],
	["cheat", "cheated", "cheating", ""],
	["defraud", "defrauded", "defrauding", ""],
	["steal from","stolen from","stealing from",""],
	["burgle","burgled","burgling",""],
	["devalue","devalued","devaluing",""],
	["rip off","ripped off","ripping off",""],
	["molest","molested","molesting",""],
	["have sex with","had sex with","having sex with",""],
	["impregnate", "impregnated", "impregnating", ""],
	["steal the identity of","stolen the identity of","stealing the identity of",""],
	["destroy","destroyed","destroying",""],
	["kill","killed", "killing",""],
	["ruin","ruined","ruining",""],
	["hurt","hurt", "hurting",""]
];

# Objects (i.e. saintly, saintly things)
my $objects = [
	"the british people",
	"the middle class",
	"middle britain",
	"england",
	"hard-working families",
	"homeowners",
	"pensioners",
	"drivers",
	"taxpayers",
	"taxpayers' money",
	"house prices",
	"property prices", # Hahahahahahahaa
	"britain's farmers",
	"britain's fishermen",
	"the countryside",
	"british justice",
	"british sovereignty",
	"common sense and decency",
	"the queen",    # God bless 'er
	"the king",     # God bless 'im
	"the royal family",
	"the church",
	"you",
	"your mortgage",
	"your pension",
	"your daughters",
	"your children",
	"your house",
	"your pets",
	"the conservative party",  # FAIL
	"cliff richard",           # Should this be in here?
	"the memory of diana",
	"Britain's swans",         # This always stays
  "Brexit",
];

# Matches an auxiliary verb with the subject
sub _match_verb_and_subject {
  my ($subject,$verb) = @_;

	if ($subject->[NUMBER] == 1 && $subject->[PERSON] == 3) {
		 return $verb->[SINGULAR];
	}
	else {
		 return $verb->[PLURAL];
	}
}

# Matchs the transitive verb's tense with that of the verb
#function Phrase(present, past, active, object) {
sub _match_verb_and_tense {
  my ($verb,$phrase) = @_;
	if ($verb->[TENSE] eq "present") {
		return $phrase->[PRESENT];
	}
	elsif ($verb->[TENSE] eq "past") {
		return $phrase->[PAST];
	}
	elsif ($verb->[TENSE] eq "active") {
		return $phrase->[ACTIVE];
	}
}

#  Returns a Daily Mail Headline as a string
sub get_headline {
	my @sentence;

  my $subject = _getRandom($subjects);
	my $phrase = _getRandom($transitive_phrases);
	my $verb = _getRandom($auxiliary_verbs);
	my $object = _getRandom($objects);

	$sentence[0] = _match_verb_and_subject($subject, $verb);
	$sentence[1] = $subject->[WORD];
	$sentence[2] = _match_verb_and_tense($verb, $phrase);
	$sentence[3] = $object;
  $sentence[4] = $phrase->[OBJECT] if $phrase->[OBJECT];

	my $s = join ' ', map { uc } @sentence;
	$s .= '?';

	return $s;
}

qq[BLOODY IMMIGRANTS];

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Daily::Fail - generate random newspaper headlines

=head1 VERSION

version 1.22

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Acme::Daily::Fail qw(get_headline);

  print get_headline(), "\n";

=head1 DESCRIPTION

Acme::Daily::Fail provides a single function that when called generates a
random newspaper headline which is typical for a certain UK newspaper title.

=head1 NAME

=head1 FUNCTION

=over

=item C<get_headline>

Not exported by default, takes no parameters, returns a randomly generated headline.

=back

=head1 BASED ON

Based on the Daily-Mail-o-matic by Chris Applegate
L<http://www.qwghlm.co.uk/toys/dailymail/>

=head1 SEE ALSO

L<http://www.qwghlm.co.uk/toys/dailymail/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Applegate and Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
