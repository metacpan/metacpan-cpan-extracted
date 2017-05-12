package Acme::Given::Hash;
{
  $Acme::Given::Hash::VERSION = '0.007';
}
use strict;
use warnings;
require 5.014;
use List::MoreUtils qw{natatime};
use Exporter qw{import};
use v5.10;
no if $] >= 5.018, warnings => "experimental::smartmatch";
our @EXPORT = qw{gvn};

#ABSTRACT: is given() too much typing for you?

sub gvn ($) {
  my $when = shift;
  # old hashref notation
  if ( ref($when) eq 'HASH' ) {
    return bless {exact => $when, calculate => []}, 'Acme::Given::Hash::Object';
  }
  # new arrayref notation
  elsif ( ref($when) eq 'ARRAY' ) {
    my $input = natatime 2, @{ $_[0] };
    my $self = {exact=>{}, calculate=>[]};
    my $it = natatime 2, @$when;
    while (my @pairs = $it->()) {
      if( ref($pairs[0]) eq '' ) {
        $self->{exact}->{$pairs[0]} = $pairs[1];
      }
      else {
        push @{ $self->{calculate} }, {match => $pairs[0], value => $pairs[1]};
      }
    }
    return bless $self, 'Acme::Given::Hash::Object';
  }
  die 'gvn only takes hashrefs and arrayrefs, you have passed soemthing else';
}

package Acme::Given::Hash::Object;
{
  $Acme::Given::Hash::Object::VERSION = '0.007';
}
use strict;
use warnings;
use v5.10;
no if $] >= 5.018, warnings => "experimental::smartmatch";

use overload '~~' => sub{
  my ($self, $key) = @_;

  # in the case of a sub as a value execute with $key
  sub RUN($){
    my $ref = shift;
    return ref($ref) eq 'CODE' ? $ref->($key) : $ref;
  }

  # first check and see if we have an exact match
  return RUN $self->{exact}->{$key} if exists $self->{exact}->{$key};

  local $_ = $key; # allow match subs to just use $_;
  foreach my $pair (@{ $self->{calculate} } ) {

    my $match;
    # 'string' ~~ [1..10] throws a warning, this disables this just for the check
    { no warnings qw{numeric};
      # in the case of a sub as a key capture the return value
      $match = ref($pair->{match}) eq 'CODE'
             ? $pair->{match}->($key)
             : $key ~~ $pair->{match}
             ;
    }

    return RUN $pair->{value} if $match;
  }
  return undef; # no matches found
};

1;
