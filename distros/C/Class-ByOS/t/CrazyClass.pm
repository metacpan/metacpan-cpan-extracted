package t::CrazyClass;

use Class::ByOS;

sub __new
{
   my $class = shift;
   return bless {}, $class;
}

sub mode { "sane" }

1;
