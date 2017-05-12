
# basic.t
#
# Tests out basic functionality of Attribute::Default. 
#
# $Revision$

use strict;
use diagnostics;

#########################

use Test::More tests => 14;
use Attribute::Default;
ok(1); # If we made it this far, we're ok.

#########################

{
  package Attribute::Default::Test;

  use base qw(Exporter Attribute::Default);

  no warnings 'uninitialized';

  our @EXPORT = qw(single double hash_vals method_hash single_defs double_defs);

  sub single : Default('single value') {
    return "Here I am: " . join(',', @_);
  }

  sub double : Default('two', 'values') {
    return "Two values: " . join(',', @_);
  }

  sub hash_vals : Default({ val1 => 'val one', val2 => 'val two'}) {
    my %args = @_;
    return "Val 1 is $args{val1}, val 2 is $args{val2}";
  }

  sub banish :method : Default({ falstaff => 'Plump Jack' }) {
    my $self = shift;
    my %args = @_;

    unless ( UNIVERSAL::isa($self, __PACKAGE__) ) {
      Test::More::diag("First argument is of incorrect package: \$self is '$self'");
      return;
    }
    
    return "Banish $args{falstaff}, and banish all the world.";
  }

  sub new : method {
    my $type = shift;
    my $self = {};
    bless $self, $type;
  }

  sub imitate :method :Defaults({ character => 'Prince Hal', quote => 'And yet herein will I imitate the sun'}) {
    my $self = shift;
    my ($in) = @_;

    return "$in->{character}: $in->{quote}";
  } 

  sub single_defs : Defaults({ type => 'black', name => 'darjeeling', varietal => 'makaibari' }) {
    my ($args) = @_;

    return "Type: $args->{'type'}, Name: $args->{'name'}, Varietal: $args->{'varietal'}";
  }

  sub double_defs : Defaults({ 'item' => 'polonious'}, 'fishmonger', [3]) {
    my ($foo, $bar, $baz) = @_;

    return "$foo->{'item'} $bar @$baz";
  }

}

Attribute::Default::Test->import();

is(single(), "Here I am: single value");
is(single('other value'), "Here I am: other value");
is(double(), "Two values: two,values");
is(double('another', 'value'), "Two values: another,value");
is(double('one is different'), "Two values: one is different,values");
my $test;
TODO: {
	local $TODO = "Fixing Attribute::Handlers interface change";
	is(hash_vals(), "Val 1 is val one, val 2 is val two");
	is(hash_vals(val2 => 'totally'), "Val 1 is val one, val 2 is totally");
	$test = Attribute::Default::Test->new();
	is($test->banish(), "Banish Plump Jack, and banish all the world.");
}
is($test->imitate(), "Prince Hal: And yet herein will I imitate the sun");

is(single_defs(), "Type: black, Name: darjeeling, Varietal: makaibari");
is(single_defs({ varietal => 'Risheehat First Flush'}), "Type: black, Name: darjeeling, Varietal: Risheehat First Flush");
is(double_defs(), 'polonious fishmonger 3');
is(double_defs({item => 'hamlet'}, 'dane', [undef, 5]), 'hamlet dane 3 5');

