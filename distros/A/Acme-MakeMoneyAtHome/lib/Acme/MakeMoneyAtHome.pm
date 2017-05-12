package Acme::MakeMoneyAtHome;
$Acme::MakeMoneyAtHome::VERSION = '1.004001';
use strict; use warnings;

use Exporter 'import'; 
our @EXPORT = 'make_money_at_home';

our @Subject = (
  "roommate",
  "cousin",
  [ "mother", 'F' ],
  [ "father", 'M' ],
  [ "sensei", 'M' ],
  "associate",
  "senator",
  "friend",
  [ "aunt", 'F' ],
  "employer",
  "car dealer",
  [ "housemaid", 'F' ],
  "limousine driver",
  "study partner",
  [ "half-sister", 'F' ],
  [ "step-uncle", 'M' ],
  "Perl mentor",
  "third cousin",
  [ "mother-in-law", 'F' ],
  [ "father-in-law", 'M' ],
  "tennis partner",
  "gym spotter",
  "statistician",
  "hairdresser",
  "dungeon master",
  "priest",
  "BFF",
  [ "sugar daddy", 'M' ],
  "secret lover",
  [ "great grandmother", 'F' ],
  "retarded parakeet",
  "chemistry assistant",
  "meth cook",
  "crippled dog",
  "deaf cat",
  "PHP advisor",
  "personal trainer",
  "neighbor",
  "lacrosse teammate",
  "distant Russian relative",
  "personal cheerleader",
  "autistic goldfish",
  "dishwasher",
  "valet",
  "caddy",
  "system administrator",
);

our @Activity = (
  "photoshopping dicks",
  "browsing 4chan",
  "posting memes",
  "mining scamcoins",
  "browsing CPAN",
  "avoiding honest work",
  "being a fucktard on Tumblr",
  "smoking weed",
  "scamming people",
  "writing to Nigerian princes",
  "collecting reddit karma",
  "mocking celebrities",
  "playing Farm Birds on MyFace+",
  "IRCing",
  "answering fetish surveys",
  "finding version.pm bugs",
  "blowing cocaine",
  "swiping Tinder",
  "posting to stackoverflow",
  "watching pornography",
  "measuring midgets",
);


sub make_money_at_home {
  my $activity = $Activity[rand @Activity];

  my @people;
  do {
    my $new_subj = $Subject[rand @Subject];
    $new_subj = $new_subj->[0] if ref $new_subj and @people < 2;
    push @people, $new_subj unless grep {; $_ eq $new_subj } @people;
  } until @people == 3;

  my $unemploy = (int rand 36) + 4;
  my $hourly   = (int rand 60) + 40;
  my $monthly  = (60 * $hourly) + sprintf '%.2f', rand(200);

  my @gender;
  if (ref $people[2] eq 'ARRAY') {
    my ($actual, $mf) = @{ $people[2] };
    $people[2] = $actual;
    @gender = $mf eq 'M' ? ( 'He', 'his' ) : ( 'She', 'her' );
  } else {
    @gender = int rand 2 ? ( 'He', 'his' ) : ( 'She', 'her' );
  }

  "My $people[0]'s $people[1]'s $people[2] makes \$$hourly an hour on the "
  ."computer. $gender[0] has been without work for $unemploy months but last "
  ."month $gender[1] pay was \$$monthly from just $activity "
  ."a few hours per day."
}

print make_money_at_home."\n" unless caller; 1;


=pod

=head1 NAME

Acme::MakeMoneyAtHome - I made 17047 dollars just posting Acme dists to CPAN

=head1 SYNOPSIS

  use Acme::MakeMoneyAtHome;
  print make_money_at_home();

=head1 DESCRIPTION

Exports the function B<make_money_at_home>, which can tell you how
much money your father's gym spotter's autistic goldfish made last month just
browsing 4chan a few hours per day.

=head1 CONTRIBUTORS

Perl-ified and maintained by Jon Portnoy <avenj@cobaltirc.org>

This Perl implementation is based on JavaScript written by B<Gilded>, whose
real name I'll put here if he ever trusts me enough to tell me.

=head1 LICENSE

Licensed under the same terms as Perl.

=cut
