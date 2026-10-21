#!perl

use v5.26;

use Test2::V0 -no_srand => 1;

use Object::Pad::MOP::Class qw( :experimental(mop) );

use Algorithm::UrataniTakeda;

my @patterns = qw( attack malware );
my $m = Algorithm::UrataniTakeda->new( patterns => \@patterns );

my $meta   = Object::Pad::MOP::Class->for_class('Algorithm::UrataniTakeda');
my $fails  = $meta->get_field('$fails');
my $states = $meta->get_field('$states');

sub memo_entries {
    my $n = 0;
    $n += scalar keys %{ $_ // {} } for @{ $fails->value($m) };
    return $n;
}

my %alpha = map { $_ => 1 } map { unpack "U*", $_ } @patterns;
my $bound = @{ $states->value($m) } * ( 1 + keys %alpha );

# text made of thousands of distinct characters that occur in no pattern
my $noise = join '', map { chr } grep { !$alpha{$_} } 0x2000 .. 0x4000;

is [ $m->matches($noise) ], [], 'noise text has no matches';

my $after_noise = memo_entries();
ok $after_noise <= $bound, "memo bounded by states x (alphabet + 1) after searching distinct characters"
  or note "memo entries: $after_noise, bound: $bound";

is [ $m->matches("$noise attack $noise malware") ], [qw( attack malware )], 'patterns still found after the noise';

is [ $m->matches($noise) ], [], 'noise text still has no matches';

is memo_entries(), $after_noise + ( memo_entries() - $after_noise ), 'memo is still consulted';

done_testing;
