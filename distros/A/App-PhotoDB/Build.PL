use Module::Build;
use Pod::Select;

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code => q{
		sub ACTION_docs {
			use Pod::Select;
			my $self = shift;
			podselect({ -output => 'README.pod' }, 'lib/App/PhotoDB.pm');
			return $self->SUPER::ACTION_docs;
		}
	}
);

my $builder = $class->new(
	module_name => 'App::PhotoDB',
	dist_author => 'Jonathan Gazeley <me@jonathangazeley.com>',
	license  => 'perl',
	configure_requires => {
		'Module::Build' => 0,
		'Pod::Select' => 0,
	},
	build_requires => {
		'Pod::Select' => 0,
		'Test::More' => 0,
	},
	requires => {
		'Config::IniHash' => 0,
		'DBD::mysql' => 0,
		'DBI' => 0,
		'Exporter' => 0,
		'Image::ExifTool' => 0,
		'SQL::Abstract' => 0,
		'strict' => 0,
		'warnings' => 0,
		'YAML' => 0,
		'Perl::Critic' => 0,
		'experimental' => 0,
		'Path::Iterator::Rule' => 0,
		'Array::Utils' => 0,
		'File::Basename' => 0,
		'Text::TabularDisplay' => 0,
		'Getopt::Long' => 0,
		'Term::ReadKey' => 0,
		'DB::SQL::Migrations' => 0,
		'Term::ReadLine' => 0,
		'Term::ReadLine::Perl' => 0,
		'Time::Piece' => 0,
	},
	test_requires => {
		'Test::More' => '0.47',
		'Test::Perl::Critic' => 0,
		'Test::Compile' => 0,
		'Test::Expect' => 0,
		'Test::Output' => 0,
		'DB::SQL::Migrations' => 0,
	},
);
$builder->create_build_script();
