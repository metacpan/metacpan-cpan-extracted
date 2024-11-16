package Data::Annotation::Expression::Builtin;
use v5.24;
use utf8;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

sub factory ($parse_ctx, $name) {
   state $immediate_for = {

      # numeric comparisons
      '<'   => sub ($l, $r) { $l  <  $r },
      '<='  => sub ($l, $r) { $l <=  $r },
      '>'   => sub ($l, $r) { $l  >  $r },
      '>='  => sub ($l, $r) { $l >=  $r },
      '=='  => sub ($l, $r) { $l ==  $r },
      '!='  => sub ($l, $r) { $l !=  $r },
      '<=>' => sub ($l, $r) { $l <=> $r },

      # string comparisons
      lt    => sub ($l, $r) { $l lt  $r },
      le    => sub ($l, $r) { $l le  $r },
      gt    => sub ($l, $r) { $l gt  $r },
      ge    => sub ($l, $r) { $l ge  $r },
      eq    => sub ($l, $r) { $l eq  $r },
      ne    => sub ($l, $r) { $l ne  $r },
      cmp   => sub ($l, $r) { $l cmp $r },

      # regular expression match/unmatch
      match   => \&match,
      '=~'    => \&match,
      unmatch => \&unmatch,
      '!~'    => \&unmatch,

      # boolean operators
      and => sub (@os) { for my $o (@os) { return 0 if !$o } ; 1 },
      or  => sub (@os) { for my $o (@os) { return 1 if  $o } ; 0 },
      not => sub ($o)  { return !$o },
      xor => sub ($r, @os) { $r = ($r xor $_) for @os; return $r },

      # set operations
      union                => \&set_union,
      U                    => \&set_union,
      '⋃'                  => \&set_union,
      intersection         => \&set_intersection,
      '⋂'                  => \&set_intersection,
      less                 => \&set_less,
      symmetric_difference => \&set_symmetric_difference,
      is_superset_of       => \&set_is_superset_of,
      '⊇'                  => \&set_is_superset_of,
      is_subset_of         => \&set_is_subset_of,
      '⊆'                  => \&set_is_subset_of,
      is_element_of        => \&set_is_element_of,
      '∈'                  => \&set_is_element_of,
      contains             => \&set_contains,
      '∋'                  => \&set_contains,
      sets_are_same        => \&sets_are_same,
      set_size             => sub ($s) { return scalar($s->@*)      },
      set_is_empty         => sub ($s) { return scalar($s->@*) == 0 },

      # other utilities
      array => sub ($x) {
         ref($x) eq 'ARRAY' ? $x : defined($x) ? [ $x ] : [];
      },
      trim => sub ($x) {
         return $x =~ s{\A\s+|\s+\z}{}rgmxs unless ref($x) eq 'ARRAY';
         return [ map { s{\A\s+|\s+\z}{}rgmxs } $x->@* ];
      },

   };
   return $immediate_for->{$name} if exists($immediate_for->{$name});
   return; # nothing found, sorry!
}

sub match   ($string, $rx) { scalar($string =~ m{$rx}) }

sub unmatch ($string, $rx) { scalar($string !~ m{$rx}) }

sub sets_are_same ($lhs, $rhs) {
   my %in_lhs = map { $_ => 1 } $lhs->@*;
   my %seen_in_rhs;
   for my $item ($rhs->@*) {
      next if $seen_in_rhs{$item}++;
      return 0 unless exists($in_lhs{$item});
      delete($in_lhs{$item});
   }
   return scalar(keys(%in_lhs)) == 0;
}

sub set_contains ($set, $target) {
   for my $item ($set->@*) { return 1 if $item eq $target }
   return 0;
}

sub set_intersection (@lists) {
   return [] unless @lists;

   my $first = shift(@lists);
   return [ $first->@* ] unless @lists;

   my $whole;
   $whole->{$_} = 1 for $first->@*;
   for my $list (@lists) {
      return [] unless scalar(keys($whole->%*));
      ($whole, my $previous) = ({}, $whole);
      for my $item ($list->@*) {
         $whole->{$item} = 1 if $previous->{$item}
      }
   }
   return set_sorted_result($whole);
}

sub set_is_element_of ($elem, $set) { return set_contains($set, $elem) }

sub set_is_subset_of ($lh, $rh) { return set_is_superset_of($rh, $lh) }

sub set_is_superset_of ($lhs, $rhs) {
   my %in_lhs = map { $_ => 1 } $lhs->@*;
   for my $item ($rhs->@*) {
      return 0 unless exists($in_lhs{$item});
   }
   return 1;
}

sub set_less ($lhs, $rhs) {
   my %in_rhs = map { $_ => 1 } $rhs->@*;
   my %result = map { $_ => 1 } grep { ! $in_rhs{$_} } $lhs->@*;
   return set_sorted_result(\%result);
}

sub set_sorted_result ($href) { [ sort { $a cmp $b } keys($href->%*) ] }

sub set_symmetric_difference ($lhs, $rhs) {
   my %result = map { $_ => 1 } $lhs->@*;
   my %in_rhs = map { $_ => 1 } $rhs->@*;
   for my $item (keys(%in_rhs)) {
      if (exists($result{$item})) { delete($result{$item}) }
      else                        { $result{$item} = 1     }  # add it
   }
   return set_sorted_result(\%result);
}

sub set_union (@lists) {
   my %whole;
   for my $list (@lists) { $whole{$_} = 1 for $list->@* }
   return set_sorted_result(\%whole);
}

1;
