use Test::More;
use Test::Exception;
use Csistck;

plan tests => 4;

ok(Csistck::Test::File->new('test', src=>'test')->can('repair'));
ok(Csistck::Test::Template->new('test', src=>'test')->can('repair'));
ok(Csistck::Test::Script->new('test')->can('repair'));
ok(Csistck::Test::Pkg->new('test', type => 'dpkg')->can('repair'));

1;
