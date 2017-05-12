use 5.008008;
use strict;
use inc::Module::Install 0.94;

# Workaround for the fact that Module::Install loads the modules
# into memory and when Test::NoWarnings is loaded it will hide
# the warnings generated from that point.
eval {
	require Test::NoWarnings;
	$SIG{__WARN__} = 'DEFAULT';
};

#####################################################################
# Normal Boring Commands

# NOTE: Core modules that aren't dual-life should always have a version of 0

name 'CPAN-Digger';
license 'perl';
author 'Gabor Szabo';
all_from 'lib/CPAN/Digger.pm';

requires 'perl' => '5.008008';

requires 'autodie'       => '2.13';
requires 'Archive::Any'  => '0.0932';
requires 'Archive::Zip'  => '1.30';
requires 'Archive::Tar'  => '1.90';
requires 'Capture::Tiny' => '0.10';
requires 'Carp';
requires 'Cwd';
requires 'Dancer' => '1.3110';
requires 'Data::Dumper';
requires 'DBI'    => '1.623';
requires 'DBD::SQLite' => '1.37';
requires 'Encode' => '2.47';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Copy::Recursive' => '0.38';
requires 'File::Find::Rule'      => '0.33';
requires 'File::Path';
requires 'File::ShareDir' => '1.03';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'JSON::XS' => '2.33';
requires 'JSON'     => '2.53';
requires 'List::Util';
requires 'Moose'                     => '2.0604';
requires 'MooseX::StrictConstructor' => '0.19';

#requires 'Parse::CPAN::Authors';
requires 'Parse::CPAN::Packages'       => '2.38';
requires 'Parse::CPAN::Whois'          => '0.02';

requires 'Perl::Critic'                => '1.118';
requires 'Perl::Critic::Bangs'         => '1.10';
requires 'Perl::Critic::Compatibility' => '1.001';
requires 'Perl::Critic::Deprecated'    => '1.108';
#requires 'Perl::Critic::Dynamic'       => '0.05'; # failed on Windows 5.12.3
#requires 'Perl::Critic::Git'           => '1.1.2'; # failed on Windows 5.12.3
requires 'Perl::Critic::Itch'          => '0.07';
requires 'Perl::Critic::Lax'           => '0.009';
#requires 'Perl::Critic::logicLAB'      => '0.05';
requires 'Perl::Critic::More'          => '1.000';
requires 'Perl::Critic::Nits'          => '1.0.0';
requires 'Perl::Critic::OTRS'          => '0.02';
requires 'Perl::Critic::PetPeeves::JTRAMMELL' => '0.02';
requires 'Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign'      => '1.0.2';
# requires 'Perl::Critic::Policy::Dynamic::NoIndirect'                  => '0.06'; # failed on Windows 5.12.3
requires 'Perl::Critic::Policy::CodeLayout::ProhibitSpaceIndentation' => '1.02';
requires 'Perl::Critic::Policy::logicLAB::RequireSheBang'             => '0.03';
requires 'Perl::Critic::Policy::logicLAB::RequireVersionFormat'       => '0.03';
requires 'Perl::Critic::Policy::logicLAB::ProhibitUseLib'             => '0.01';
requires 'Perl::Critic::Policy::logicLAB::ProhibitShellDispatch'      => '0.01';
requires 'Perl::Critic::RENEEB'          => '0.01';
requires 'Perl::Critic::StricterSubs'    => '0.03';
requires 'Perl::Critic::Storable'        => '0.01';
requires 'Perl::Critic::Swift'           => '1.0.3';
requires 'Perl::Critic::Pulp'            => '75';
requires 'Perl::Critic::Tics'            => '0.006';

requires 'Perl::MinimumVersion'          => '1.31';
requires 'POSIX';
requires 'PPI::Document'                 => '1.215'; # PPI
requires 'PPI::Find'                     => '1.215'; # PPI
requires 'PPIx::EditorTools'             => '0.18';
requires 'Template'                      => '2.24';
requires 'Time::HiRes';
#requires 'YAML::Any' => '0.72';
requires 'YAML'      => '0.84';

requires 'Pod::Simple' => '3.23';
requires 'Pod::Simple::HTML';  # in Pod-Simple
requires 'Plack' => '1.0014';
requires 'Plack::Runner'; # no version ? in Plack
requires 'Plack::Handler::FCGI'; # in Plack
requires 'Plack::Util';  # in Plack


test_requires 'Test::Deep'       => '0.110';
test_requires 'Test::More'       => '0.98';
test_requires 'Test::NoWarnings' => '1.04';

no_index 'directory' => qw{ t xt eg share inc privinc };

install_script 'script/cpan_digger.pl';
homepage 'http://cpandigger.com/';
repository 'https://github.com/szabgab/CPAN-Digger';

eval {
	require File::Copy::Recursive;
	mkdir 'share';

	# config.yml
	# environmaents
	foreach my $dir (qw(public schema bin view)) {
		File::Copy::Recursive::rcopy( $dir, "share/$dir" );
	}

	install_share();
};

WriteAll;

