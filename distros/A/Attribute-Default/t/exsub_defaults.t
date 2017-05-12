# exsub_defaults.t
#
# Tests out expanding subroutines on Defaults().
#

use strict;
use warnings;
use diagnostics;

#####################

use Test::More tests => 5;
use Attribute::Default;

{
  package Attribute::Default::TestExpand;
  use Attribute::Default 'exsub';
  use base qw(Attribute::Default);
  use UNIVERSAL;
  use Data::Dumper;

  sub multi_subs : Defaults( [ 'caius', 'martius', 'coriolanus' ], exsub { [ reverse @{ $_[0] } ] } ) {
    unless ( UNIVERSAL::isa($_[0], 'ARRAY') ) {
      Test::More::diag("Arg 1 is not an array ref.", Dumper([@_]));
      return;
    }
    unless (UNIVERSAL::isa($_[1], 'ARRAY') ) {
      Test::More::diag("Arg 2 is not an array ref.", Dumper([@_]));
      return;
    }
    return "@{$_[0]} is backward @{$_[1]}";
  }

  sub threefaces_sub  : Defaults(3, exsub { $_[0] + 1 }, { foo => exsub { $_[0] + 2 } } ) {
    no warnings 'uninitialized';
    return "$_[0] $_[1] $_[2]{'foo'}";
  }

  sub new { my $self = [3]; bless $self; }

  sub exp_meths :method :Defaults({bar => exsub { _check_and_mult($_[0], 3); }}) {
    my $self = shift;
    return $_[0]{bar};
  }

  sub defaults_hash_expansion :Defaults({baz => exsub { $_[0]->{'pip'} * 2}, pip => 3}) {
    unless (defined $_[0]) {
      Test::More::diag("First argument not defined");
      return;
    }
    return $_[0]->{'baz'};
  }

  sub _check_and_mult {
    my $self = shift;
    my ($factor) = @_;
    
    unless (@_ == 1) {
      Test::More::diag("Expanded sub got wrong number of arguments: @{[ scalar @_ ]}");
      return;
    }
    unless (UNIVERSAL::isa($self, __PACKAGE__)) {
      Test::More::diag("Expanded sub got wrong kind of type for \$self: $self");
      return;
    }
    return $self->[0] * $factor;
  }
}

is(Attribute::Default::TestExpand::multi_subs(), 'caius martius coriolanus is backward coriolanus martius caius');
is(Attribute::Default::TestExpand::threefaces_sub(), "3 4 5");
is(Attribute::Default::TestExpand::threefaces_sub(2), "2 3 4");
is(Attribute::Default::TestExpand::defaults_hash_expansion(), 6, "Expansion of default in Defaults() for hash");
{
  my $testobj = Attribute::Default::TestExpand->new();
  is($testobj->exp_meths(), 9);
}

