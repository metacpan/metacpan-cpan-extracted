use strict;
use Test::More 0.98;


package Obj;
sub new {
  my $class = shift;
  bless +{}, $class;
}

sub some_method {
  my $self = shift;
  "some method";
}

package main;

use Acme::Ane qw(ane);

sub ane_check {
  my $ane = shift;
  ok $ane->is_ane, "is ane.";
  is $ane->some_method, "some method", "can be called original method";
  eval { $ane->wrong_method };
  like $@, qr/Can't locate/, "cannot be called wrong method";
  isa_ok $ane, "Acme::Ane", "isa Acme::Ane";
}

my $obj = Obj->new;
my $ane1 = Acme::Ane->new($obj);

ane_check $ane1;

my $another = Obj->new;
my $ane2 = ane($another);

ane_check $ane2;

done_testing;
