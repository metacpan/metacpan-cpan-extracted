use inc::Module::Install;
name            'DBIx-Changeset';
author			'Grox Pty Ltd <modules@grox.com.au>';
all_from        'lib/DBIx/Changeset.pm';

requires('App::Cmd' => 0);
requires('Class::Accessor' => '0.31');
requires('Data::UUID' => 0);
requires('Digest::MD5' => 0);
requires('Encode' => 0);
requires('File::Basename' => 0);
requires('File::Spec' => 0);
requires('Shell' => 0);
requires('Class::Factory' => 0);
requires('Exception::Class' => 0);
requires('Exception::Class::DBI' => 0);
requires('File::Slurp' => '9999.13');
requires('Term::Report' => 0);
requires('Term::Prompt' => '1.03');
requires('Hash::Merge' => '0.07');
requires('Data::Phrasebook' => 0 );
requires('Data::Phrasebook::Loader::YAML' => 0 );
requires('DateTime::Format::ISO8601' => 0 );
requires('Path::Class');
requires('File::ShareDir');
requires('DateTime' => 0);
requires('YAML' => 0);
requires('DBI' => 0);

build_requires('Test::More' => '0');
build_requires('Test::Exception' => '0');
build_requires('Test::Output' => '0');
build_requires('File::ShareDir::Install' => '0');

feature('Testing with SQLite',
	'-default' => 0,
	'DBD::SQLite' => '1.11',
);

feature('Testing with Perl Critic',
	'-default' => 0,
	'Test::Perl::Critic' => '1.01',
);

feature('POD Testing',
	'-default' => 0,
	'Test::Pod::Coverage' =>  1.04,
	'Test::Pod' =>  1.14,
);

auto_install;
install_script('./bin/dbix_changeset.pl');
install_share;
WriteAll;
