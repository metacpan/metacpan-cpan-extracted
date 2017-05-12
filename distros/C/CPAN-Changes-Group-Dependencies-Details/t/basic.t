use strict;
use warnings;

use Test::More tests     => 100;
use constant UBERVERBOSE => 0;
use if UBERVERBOSE, Encode => qw( encode );
use Test::Differences;

# ABSTRACT: Basic comparison

use CPAN::Changes::Group::Dependencies::Details;

# Changes.deps.all
my $set = [];
for my $change (qw( Added Changed Upgrade Downgrade Removed )) {
  for my $phase (qw( configure build runtime test develop )) {
    for my $rel (qw( requires recommends suggests )) {
      push @{$set}, { 'change_type' => $change, phase => $phase, type => $rel };
    }
  }
}
use CPAN::Meta::Prereqs;

my @prereqs = (
  map { CPAN::Meta::Prereqs->new($_) }{},
  { runtime   => { requires   => { 'Moo' => '0' } } },
  { runtime   => { requires   => { 'Moo' => '1.0' } } },
  { runtime   => { requires   => { 'Moo' => '2.0' } } },
  { runtime   => { suggests   => { 'Moo' => '2.0' } } },
  { runtime   => { recommends => { 'Moo' => '2.0' } } },
  { develop   => { requires   => { 'Moo' => '2.0' } } },
  { configure => { requires   => { 'Moo' => '2.0' } } },
  { build     => { requires   => { 'Moo' => '2.0' } } },
  { test      => { requires   => { 'Moo' => '2.0' } } },
);

use Scalar::Util qw(refaddr);

for my $old (@prereqs) {
  for my $new (@prereqs) {

    my @out;
    for my $item ( @{$set} ) {
      my $diff = CPAN::Changes::Group::Dependencies::Details->new(
        old_prereqs => $old,
        new_prereqs => $new,
        %{$item},
      );
      my $changes;
      if ( @{ $changes = $diff->changes } ) {
        push @out, '[' . $item->{change_type} . ' / ' . $item->{phase} . q[ ] . $item->{type} . ']';
        push @out, @{$changes};
      }
    }

    if ( refaddr $old eq refaddr $new ) {
      eq_or_diff( \@out, [], 'No Changes if old == new' );
    }
    else {
      if (UBERVERBOSE) {
        note explain { new => $new->as_string_hash, old => $old->as_string_hash };
        note join qq[\n], map { Encode::encode( ':UTF-8', $_, Encode::FB_CROAK() ) } @out;
      }
      isnt( scalar @out, 0, 'Some changes if refaddr changes w/ all' );
    }
  }
}
