use Data::Skeleton;
use Test::More;

my $page = {};
$page->{circular} = $page;
my $s = Data::Skeleton->new;
ok($s->deflesh($page));

$page = [];
$page->[0] = $page;
$s = Data::Skeleton->new;
ok($s->deflesh($page));

done_testing;
