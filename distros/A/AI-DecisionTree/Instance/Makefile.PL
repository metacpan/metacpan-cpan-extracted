
use ExtUtils::MakeMaker;

my $module = 'AI::DecisionTree::Instance';
my ($name, $dir);
($name = $module) =~ s/.*::(\w+)/$1.pm/;
($dir  = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'       => $module,
   'VERSION_FROM' => $name, # finds $VERSION
  );

