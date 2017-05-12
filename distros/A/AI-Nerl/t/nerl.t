use Test::More tests=>2;
use Modern::Perl;
use PDL;
use_ok('AI::Nerl');
{
   my $nerl = AI::Nerl->new();
   isa_ok($nerl,'AI::Nerl');
}

{
   my $x = pdl([0,0,1,1],[0,1,0,1]);
   my $AND = pdl(0,0,0,1);
   my $OR = pdl(0,1,1,1);
   my $XOR = pdl(0,1,1,0);

   my $AND_nerl = AI::Nerl->new(
      train_x => $x,
      train_y => $AND,
   );
   $AND_nerl->build_network;
   my $AND_output = $AND_nerl->run($x);

}

#task: mod 3
#in: 8 bits from (n=0..255);
#out: 1 output: (n%3 != 0)
my $x = map{split '',sprintf("%b",$_)} 0..255;
$x = pdl($x)->transpose;
my $y = pdl map{$_%3 ? 1 : 0} 0..255;
$y = identity(3)->range($y->transpose);

my $nerl = AI::Nerl->new(
   train_x => $x,
   train_y => $y,
   l2 => 4,
);

#$nerl->init_network();
$nerl->build_network();



