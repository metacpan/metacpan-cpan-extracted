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
			nested   => {
				isa   => 'HashRef',
				rules => {
					id   => 'Int',
					name => 'Str'
				}
			},
			array_of_hash => {
				isa   => 'ArrayRef|HashRef',
				rules => {
					id   => 'Int',
					name => 'Str'
				}
			},
		},
		$module,
		{
			integer  => 100,
			string   => 'hoge',
			optional => undef,
			default  => undef,
			hashref  => 'fuga',
			nested   => {
				id   => 1,
				name => 'hoge',
			},
			array_of_hash => [
				{
					id   => 1,
					name => 'hoge',
				},
				{
					id   => 2,
					name => 'fuga',
				},
			],
		}
	);

	is ref $self, 'Dwarf::Module::DSL', '$self';
	is $args->{integer}, 100, 'integer value';
	is $args->{string}, 'hoge', 'string value';
	ok !$args->{optional}, 'optional value';
	is $args->{default}, 3, 'optional value with default value';
	is $args->{hashref}, 'fuga', 'hash value';
	is_deeply $args->{nested}, { id => 1, name => 'hoge' }, 'nested value';
	is_deeply $args->{array_of_hash}, [{ id => 1, name => 'hoge' }, { id => 2, name => 'fuga' }], 'array_of_hash value';
};

done_testing;
