use 5.006;
use strict;
use warnings;

package App::GhaInstall;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

our $ALLOW_FAIL = 0;
our $DRY_RUN    = 0;

sub SHOULD_INSTALL_OPTIONAL_DEPS () {
	no warnings;
	$ENV{GHA_TESTING_COVER} =~ /^(true|1)$/i
	or $ENV{GHA_INSTALL_OPTIONAL} =~ /^(true|1)$/i
}

sub SHOULD_INSTALL_COVERAGE_DEPS () {
	no warnings;
	$ENV{GHA_TESTING_COVER} =~ /^(true|1)$/i
}

sub SHOULD_INSTALL_GITHUB_DEPS () {
	no warnings;
	!! $ENV{CI}
}

my $installer;
sub INSTALLER () {
	return $installer if defined $installer;
	if ( $ENV{GHA_INSTALL_BACKEND} ) {
		$installer = $ENV{GHA_INSTALL_BACKEND};
	}
	elsif ( $] lt '5.008001' ) {
		$installer = 'cpan';
	}
	else {
		my $output = `cpanm --version`;
		if ( $output =~ /cpanminus/ ) {
			$installer = 'cpanm';
		}
		else {
			$output = `cpm --help`;
			if ( $output =~ /install/ ) {
				$installer = 'cpm';
			}
			else {
				$installer = 'cpan';
			}
		}
	}
	ensure_configured_cpan() if $installer eq 'cpan';
	return $installer;
}

sub go {
	shift;
	
	my @modules;
	
	foreach ( @_ ) {
		if ( /--allow-fail/ ) {
			$ALLOW_FAIL = 1;
		}
		elsif ( /--dry-run/ ) {
			$DRY_RUN = 1;
		}
		elsif ( /--bootstrap/ ) {
			install_module( __PACKAGE__ );
			local $ALLOW_FAIL = 1;
			install_module( 'CPAN' ) if INSTALLER eq 'cpan';
		}
		elsif ( /--configure/ ) {
			install_configure_dependencies();
		}
		elsif ( /--auto/ ) {
			install_dependencies();
		}
		else {
			push @modules, $_;
		}
	}
	
	if ( @modules ) {
		install_modules( @modules );
	}
	
	return 0;
}

sub slurp {
	my $file = shift;
	open my $fh, '<', $file
		or die "$file exists but cannot be read\n";
	local $/;
	return <$fh>;
}

sub read_json {
	my $file = shift;
	return unless -f $file;
	
	my $hash;
	
	if ( eval { require JSON::MaybeXS; 1 } ) {
		my $json = 'JSON::MaybeXS'->new;
		$hash = $json->decode( slurp($file) );
	}
	elsif ( eval { require JSON::PP; 1 } ) {
		my $json = 'JSON::PP'->new;
		$hash = $json->decode( slurp($file) );
	}
	else {
		# Bundled version of JSON::Tiny
		require App::GhaInstall::JSON;
		$hash = JSON::Tiny::decode_json( slurp($file) );
	}
	
	return unless ref($hash) eq 'HASH';
	
	$hash->{metatype} = 'JSON';
	return $hash;
}

sub read_yaml {
	my $file = shift;
	return unless -f $file;
	
	my $hash;
	
	if ( eval { require JSON::XS; 1 } ) {
		$hash = YAML::XS::Load( slurp($file) );
	}
	else {
		# Bundled version of YAML::Tiny
		require App::GhaInstall::YAML;
		$hash = YAML::Tiny::Load( slurp($file) );		
	}
	
	return unless ref($hash) eq 'HASH';
	
	$hash->{metatype} = 'YAML';
	return $hash;
}

sub install_configure_dependencies {
	my $meta =
		read_json('META.json') || read_yaml('META.yml')
		or die("Cannot read META.json or META.yml");
	
	my ( @need, @want );
	
	if ( $meta->{metatype} eq 'JSON' ) {
		for my $phase ( qw( configure build ) ) {
			push @need, keys %{ $meta->{prereqs}{$phase}{requires}   or {} };
			push @want, keys %{ $meta->{prereqs}{$phase}{recommends} or {} };
			push @want, keys %{ $meta->{prereqs}{$phase}{suggests}   or {} };
		}
	}
	else {
		push @need, keys %{ $meta->{configure_requires} or {} };
		push @need, keys %{ $meta->{build_requires}     or {} };
	}
	
	if ( @need ) {
		install_modules( @need );
	}
	
	if ( @want and SHOULD_INSTALL_OPTIONAL_DEPS ) {
		local $ALLOW_FAIL = 1;
		install_modules( @want );
	}
	
	return;
}

sub install_dependencies {
	my $meta =
		read_json('MYMETA.json') || read_yaml('MYMETA.yml') || read_json('META.json') || read_yaml('META.yml')
		or die("Cannot read MYMETA.json or MYMETA.yml");
	
	my ( @need, @want );
	
	if ( $meta->{metatype} eq 'JSON' ) {
		for my $phase ( qw( configure build runtime test ) ) {
			push @need, keys %{ $meta->{prereqs}{$phase}{requires}   or {} };
			push @want, keys %{ $meta->{prereqs}{$phase}{recommends} or {} };
			push @want, keys %{ $meta->{prereqs}{$phase}{suggests}   or {} };
		}
	}
	else {
		push @need, keys %{ $meta->{configure_requires} or {} };
		push @need, keys %{ $meta->{build_requires}     or {} };
		push @need, keys %{ $meta->{requires}           or {} };
		push @need, keys %{ $meta->{test_requires}      or {} };
		push @want, keys %{ $meta->{recommends}         or {} };
	}
	
	if ( SHOULD_INSTALL_GITHUB_DEPS ) {
		push @need, 'App::GhaProve';
	}
	
	if ( SHOULD_INSTALL_COVERAGE_DEPS ) {
		push @need, 'Devel::Cover';
		push @need, 'Devel::Cover::Report::Coveralls';
		push @need, 'Devel::Cover::Report::Codecov';
	}
	
	if ( @need ) {
		install_modules( @need );
	}
	
	if ( @want and SHOULD_INSTALL_OPTIONAL_DEPS ) {
		local $ALLOW_FAIL = 1;
		install_modules( @want );
	}
	
	return;
}

sub maybe_die {
	my $exit = shift;
	if ( $exit ) {
		if ( $ALLOW_FAIL ) {
			warn "Failed, but continuing anyway...\n";
		}
		else {
			die "Failed; stopping!\n";
		}
	}
	return;
}

sub install_modules {
	my @modules = grep $_ ne 'perl', @_;
	
	if ( $DRY_RUN ) {
		warn "install: $_\n" for @modules;
		return;
	}

	if ( INSTALLER eq 'cpanm' ) {
		return maybe_die system 'cpanm', '-n', @modules;
	}
	
	if ( INSTALLER eq 'cpm' ) {
		return maybe_die system 'cpm', 'install', '-g', @modules;
	}

	install_module($_) for @_;
}

sub install_module {
	my $module = shift;
	
	if ( $DRY_RUN ) {
		warn "install: $module\n";
		return;
	}
	
	if ( INSTALLER eq 'cpanm' ) {
		return maybe_die system 'cpanm', '-n', $module;
	}
	
	if ( INSTALLER eq 'cpm' ) {
		return maybe_die system 'cpm', 'install', '-g', $module;
	}
	
	if ( INSTALLER eq 'cpan' ) {
		my @notest = grep /^notest$/, @CPAN::EXPORT;
		'CPAN::Shell'->rematein( @notest, 'install', $module );
		if ( 'CPAN::Shell'->can('mandatory_dist_failed') ) {
			return scalar 'CPAN::Shell'->mandatory_dist_failed();
		}
		return;
	}
	
	return maybe_die system( split(/ /, INSTALLER), $module );
}

sub ensure_configured_cpan {
	use Cwd ();
	require CPAN;
	eval { require CPAN::Shell };

	my $home = $ENV{HOME};
	my $cwd  = Cwd::cwd;
	$CPAN::Config = {
	  'applypatch' => q[],
	  'auto_commit' => q[0],
	  'build_cache' => q[100],
	  'build_dir' => qq[$home/.cpan/build],
	  'build_dir_reuse' => q[0],
	  'build_requires_install_policy' => q[yes],
	  'bzip2' => q[/bin/bzip2],
	  'cache_metadata' => q[1],
	  'check_sigs' => q[0],
	  'colorize_output' => q[0],
	  'commandnumber_in_prompt' => q[1],
	  'connect_to_internet_ok' => q[1],
	  'cpan_home' => qq[$home/.cpan],
	  'ftp_passive' => q[1],
	  'ftp_proxy' => q[],
	  'getcwd' => q[cwd],
	  'gpg' => q[/usr/bin/gpg],
	  'gzip' => q[/bin/gzip],
	  'halt_on_failure' => q[0],
	  'histfile' => qq[$home/.cpan/histfile],
	  'histsize' => q[100],
	  'http_proxy' => q[],
	  'inactivity_timeout' => q[0],
	  'index_expire' => q[1],
	  'inhibit_startup_message' => q[0],
	  'keep_source_where' => qq[$home/.cpan/sources],
	  'load_module_verbosity' => q[none],
	  'make' => q[/usr/bin/make],
	  'make_arg' => q[],
	  'make_install_arg' => q[],
	  'make_install_make_command' => q[/usr/bin/make],
	  'makepl_arg' => q[INSTALLDIRS=site],
	  'mbuild_arg' => q[],
	  'mbuild_install_arg' => q[],
	  'mbuild_install_build_command' => q[./Build],
	  'mbuildpl_arg' => q[--installdirs site],
	  'no_proxy' => q[],
	  'pager' => q[/usr/bin/less],
	  'patch' => q[/usr/bin/patch],
	  'perl5lib_verbosity' => q[none],
	  'prefer_external_tar' => q[1],
	  'prefer_installer' => q[MB],
	  'prefs_dir' => qq[$home/.cpan/prefs],
	  'prerequisites_policy' => q[follow],
	  'scan_cache' => q[atstart],
	  'shell' => q[/bin/sh],
	  'show_unparsable_versions' => q[0],
	  'show_upload_date' => q[0],
	  'show_zero_versions' => q[0],
	  'tar' => q[/bin/tar],
	  'tar_verbosity' => q[none],
	  'term_is_latin' => q[1],
	  'term_ornaments' => q[1],
	  'test_report' => q[0],
	  'trust_test_report_history' => q[0],
	  'unzip' => q[/usr/bin/unzip],
	  'urllist' => [q[http://cpan.mirrors.uk2.net/], q[http://cpan.singletasker.co.uk/], q[http://cpan.cpantesters.org/]],
	  'use_sqlite' => q[0],
	  'version_timeout' => q[15],
	  'wget' => q[/usr/bin/wget],
	  'yaml_load_code' => q[0],
	  'yaml_module' => q[YAML],
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::GhaInstall - provides the gha-install command

=head1 SYNOPSIS

Install dependencies for a distribution, assuming you're in the distro's
root directory (where Makefile.PL and META.json live):

  $ gha-install --configure
  $ perl Makefile.PL
  $ gha-install --auto

Install things by name:

  $ gha-install HTTP::Tiny

Install things by name, but ignore failures:

  $ gha-install --allow-fail HTTP::Tiny

=head1 DESCRIPTION

This is a wrapper around L<App::cpanminus>, L<App::cpm>, or L<CPAN>,
depending on what is available. Mostly because L<App::cpanminus>
doesn't work on Perl 5.6.

Copies of L<YAML::Tiny> and L<JSON::Tiny> are bundled, just in case.

C<< gha-install >> is intended to be packable with L<App::FatPacker>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=App-GhaInstall>.

=head1 SEE ALSO

L<App::cpanminus>, L<App::cpm>, L<CPAN>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

