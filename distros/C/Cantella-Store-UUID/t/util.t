use strict;
use warnings;

use FindBin '$Bin';
use Test::More;
use Test::Fatal;

use Path::Class qw(file dir);
use Cantella::Store::UUID::Util '_mkdirs';

my $tmp = dir($Bin)->subdir('var')->subdir('store-test');

if( -e $tmp){
  plan tests => 515;
  ok($tmp->rmtree, "setting up environment $!");
} else {
  plan tests => 514;
}

is(exception { _mkdirs($tmp, 2) }, undef, '_mkdirs lives');

#512
for my $level_1 ( (0..9), qw(A B C D E F)){
  for my $level_2 ( (0..9), qw(A B C D E F)){
    my $display = "${level_1} / ${level_2}";
    my $path = $tmp->subdir($level_1)->subdir($level_2);
    ok(-d $path, "${display} present");
    my $children = $path->children;
    is($children, 0, "${display} empty");
  }
}

ok($tmp->rmtree, 'cleanup correctly');
