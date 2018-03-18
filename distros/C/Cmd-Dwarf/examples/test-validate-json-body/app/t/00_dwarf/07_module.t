use Dwarf::Pragma;
use Dwarf::Module;
use Dwarf::DSL;
use Test::More 0.88;

subtest "new" => sub {
	my $module = Dwarf::Module->new;
	my @list = @Dwarf::Module::DSL::FUNC;
	for my $f (@list) {
		ok $module->can($f), "can $f";
	}
};

subtest "dsl" => sub {
	my @list = @Dwarf::Module::DSL::FUNC;
	for my $f (@list) {
		ok $main::{$f}, "can $f";
	}
};

done_testing();
