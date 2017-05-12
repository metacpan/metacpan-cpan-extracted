package Dwarf::Test::Model::Hoge;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::Accessor {
	ro => [qw/readonly/],
	wo => [qw/writeonly/],
	rw => [qw/data/]
};

sub _build_readonly { 1 }

1;