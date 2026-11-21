#!/usr/bin/env perl

# Tests for the install_db_file and cpanm_verbose options of
# App::GHGen::PerlCustomizer::generate_custom_perl_workflow

use v5.36;
use Test::Most;
use YAML::XS qw(Load);

use_ok('App::GHGen::PerlCustomizer', qw(generate_custom_perl_workflow));

my %C = (
	db_step => 'Install DB_File',
	apt     => 'libdb-dev',
	verbose => '--verbose',
	install => qr/cpanm --notest --installdeps( --verbose)? \./,
);

# All "cpanm --installdeps" commands in the generated workflow
sub install_commands($yaml) {
	return [ $yaml =~ /(cpanm --notest --installdeps[^\n]*)/g ];
}

subtest 'defaults keep the DB_File step and --verbose' => sub {
	my $yaml = generate_custom_perl_workflow();
	like($yaml, qr/\Q$C{db_step}\E/, 'DB_File step present');
	like($yaml, qr/\Q$C{apt}\E/, 'apt packages present');
	my $commands = install_commands($yaml);
	is(scalar @{$commands}, 2, 'unix and windows install steps');
	like($_, qr/\Q$C{verbose}\E/, "verbose: $_") for @{$commands};
};

subtest 'install_db_file => 0 drops the DB_File step' => sub {
	my $yaml = generate_custom_perl_workflow({ install_db_file => 0 });
	unlike($yaml, qr/\Q$C{db_step}\E/, 'step absent');
	unlike($yaml, qr/\Q$C{apt}\E/, 'apt packages absent');
	lives_ok { Load($yaml) } 'still valid YAML';
	like($yaml, qr/Install dependencies/, 'dependency install kept');
};

subtest 'cpanm_verbose => 0 drops --verbose from both install steps' => sub {
	my $yaml = generate_custom_perl_workflow({ cpanm_verbose => 0 });
	my $commands = install_commands($yaml);
	is(scalar @{$commands}, 2, 'both install steps present');
	unlike($_, qr/\Q$C{verbose}\E/, "quiet: $_") for @{$commands};
	like($_, $C{install}, 'command otherwise intact') for @{$commands};
};

subtest 'the two options are independent' => sub {
	my $yaml = generate_custom_perl_workflow({ install_db_file => 0, cpanm_verbose => 1 });
	unlike($yaml, qr/\Q$C{db_step}\E/, 'DB_File step absent');
	like($_, qr/\Q$C{verbose}\E/, 'verbose kept') for @{ install_commands($yaml) };
};

done_testing();
