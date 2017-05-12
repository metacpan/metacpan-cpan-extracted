use Dwarf::Pragma;
use Dwarf::Module;
use Dwarf::DSL;
use Test::More 0.88;

subtest "args" => sub {
	my $module = Dwarf::Module->new;

	my ($self, $args) = $module->args(
		{
			integer  => 'Int',
			string   => 'Str',
			optional => 'Int?',
			default  => 'Int? = 3',
			hashref  => { isa => 'Str' },
		},
		$module,
		{
			integer  => 100,
			string   => 'hoge',
			optional => undef,
			default  => undef,
			hashref  => 'fuga',
		}
	);

	is ref $self, 'Dwarf::Module::DSL', '$self';
	is $args->{integer}, 100, 'integer value';
	is $args->{string}, 'hoge', 'string value';
	ok !$args->{optional}, 'optional value';
	is $args->{default}, 3, 'optional value with default value';
	is $args->{hashref}, 'fuga', 'hash value';
};

done_testing;
