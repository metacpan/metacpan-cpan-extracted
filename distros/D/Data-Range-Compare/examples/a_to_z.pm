package # Hid this example package from PAUSE
  a_to_z;

use strict;
use warnings;
use vars qw(@ISA @list %ids %helper);
@ISA=qw(Data::Range::Compare);
use Data::Range::Compare;

@list=('a' .. 'z');
my $id=-1;
%ids=map { ($_,++$id) } @list; 
undef $id;

$helper{add_one}=\&add_one;
sub add_one {
  my $here=$ids{$_[0]};
  ++$here;
  return 'z' if $#list<$here;
  $list[$here]
}

$helper{sub_one}=\&sub_one;
sub sub_one {
  my $here=$ids{$_[0]};
  --$here;
  return 'a' if $here<0;
  $list[$here]
}
sub cmp_values { $_[0] cmp $_[1] }
$helper{cmp_values}=\&cmp_values;

sub new{
  my ($class,$start,$end,$generated,$missing)=@_;
  $class->SUPER::new(\%helper,$start,$end,$generated,$missing);
}

sub range_compare { 
   my ($s,@args)=@_;
   $s->SUPER::range_compare(\%helper,@args) 
}

sub get_common_range {
  my ($class,@args)=@_;
  $class->SUPER::get_common_range(\%helper,@args);
}

1;

