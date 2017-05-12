use Dwarf::Pragma;
use Dwarf;
use Dwarf::Test::Config::Production;
use Test::More 0.88;

subtest 'init' => sub {
	my $c = Dwarf->new;
	my $config = Dwarf::Test::Config::Production->new(context => $c);
	ok defined $config->get('ssl');
	ok ref $config->get('db') eq 'HASH';
};

subtest 'set value' => sub {
	my $value = 1234;

	my $c = Dwarf->new;
	my $config = Dwarf::Test::Config::Production->new(context => $c);
	isnt $config->get('ssl'), $value;

	$config->set(ssl => $value);
	is $config->get('ssl'), $value;
};

subtest 'get value with Data::Path' => sub {
	my $value = 'dbi:Pg:dbname=dwarf';
	my $c = Dwarf->new;
	my $config = Dwarf::Test::Config::Production->new(context => $c);
	is $config->get('/db/master/dsn'), $value;
};

done_testing();
