#!/usr/local/bin/perl

package Y;
my $count = 0;
sub new { bless { id => $count++ }, shift; }
sub id { shift->{id}; }

package X;

use lib qw ( ./t/emulator_class_methodmaker );
use Test;

use Class::MakeMethods::Emulator::MethodMaker
  object_list  => [
		   'Y' => { slot => 'a', comp_mthds => 'id' },
		  ];

sub new { bless {}, shift; }
my $o = new X;

TEST { 1 };

TEST { $o->push_a (Y->new) };
TEST { $o->push_a (Y->new) };
TEST { $o->pop_a->id == 1  };
TEST { $o->push_a (Y->new) };
TEST { @b = $o->a; @b == 2 };
TEST { join (' ', $o->id) eq '0 2' };
TEST { $a = 1; for ($o->a) { $a &&= ( ref ($_) eq 'Y' ) }; $a };
TEST { $o->shift_a->id == 0 };
TEST { $o->unshift_a ( Y->new ) };
TEST { @b = $o->a; @b == 2 };
TEST { $a = 1; for ($o->a) { $a &&= ( ref ($_) eq 'Y' ) }; $a };
TEST { join (' ', $o->id) eq '3 2' };
TEST { ref($o->index_a(0)) eq 'Y' };
TEST { $o->set_a(0 => Y->new) };
TEST { $o->a_index(0)->id == 4};
TEST { @b = $o->a; @b == 2 };

exit 0;

