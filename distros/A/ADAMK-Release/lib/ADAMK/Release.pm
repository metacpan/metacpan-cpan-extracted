package ADAMK::Release;

use 5.10.0;
use strict;
use warnings;
use Carp                          ();
use CPAN::Uploader       0.103003 ();
use Devel::PPPort            3.21 ();
use File::Spec::Functions    0.80 ':ALL';
use File::Slurp           9999.19 ();
use File::Find::Rule         0.32 ();
use File::Flat               1.04 ();
use File::ShareDir           1.03 ();
use File::LocalizeNewlines   1.12 ();
use GitHub::Extract          0.02 ();
use IO::Prompt::Tiny        0.002 ();
use Module::Extract::VERSION 1.01 ();
use Params::Util             1.00 ':ALL';
use Term::ReadKey            2.14 ();
use YAML::Tiny               1.51 ();

our $VERSION = '0.02';

use constant TOOLS => qw{
	cat
	chmod
	make
	touch
	sudo
	bash
};

use Object::Tiny 1.01 qw{
	module
	github
	verbose
	release
	no_rt
	no_changes
	no_copyright
	no_test
}, map { "bin_$_" } TOOLS;






######################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check module
	unless ( _CLASS($self->module) ) {
		$self->error("Missing or invalid module");
	}

	# Inflate and check the github object
	if ( Params::Util::_HASH($self->github) ) {
		$self->{github} = GitHub::Extract->new( %{$self->github} );
	}
	unless ( Params::Util::_INSTANCE($self->github, 'GitHub::Extract')) {
		$self->error("Missing or invalid GitHub specification");
	}

	# Release options
	$self->{release} = !!$self->{release};

	# Find all of the command line tools
	foreach my $tool ( TOOLS ) {
		$self->{ "bin_" . $tool } = $self->which($tool);
	}

	return $self;
}





######################################################################
# Command Methods

sub run {
	my $self = shift;

	# Export from GitHub and change to the directory
	my $pushd = $self->github->pushd;
	unless ( $pushd ) {
		$self->error(
			"Failed to download and extract %s: %s",
			$self->github->url,
			$self->github->error,
		);
	}

	# This is total bulldozer coding, there is no reason whatsoever why
	# this stuff should be in seperate methods except that it provides
	# a little cleaner logical breakup, and maybe I want to subclass this
	# someday or something.
	$self->validate;
	$self->assemble;
	$self->build;

	# Release the distribution
	$self->upload if $self->release;

	return;
}

sub validate {
	my $self = shift;

	unless ( $self->dist_version ) {
		$self->error("Failed to find version number in main module");
	}
	unless ( $self->makefile_pl or $self->build_pl ) {
		$self->error("Failed to find Makefile.PL or Build.PL");
	}

	return;
}

sub assemble {
	my $self = shift;

	# Create MANIFEST.SKIP
	if ( -f $self->dist_manifest_add ) {
		$self->shell(
			$self->bin_cat,
			$self->shared_manifest_skip,
			$self->dist_manifest_add,
			'>',
			$self->dist_manifest_skip,
			"Failed to merge common MANIFEST.SKIP with extra one",
		);

	} elsif ( not -f $self->dist_manifest ) {
		$self->copy( $self->shared_manifest_skip => $self->dist_manifest_skip );
	}

	# Apply a default LICENSE file
	unless ( -f $self->dist_license ) {
		$self->copy( $self->shared_license => $self->dist_license );
	}

	# Add ppport.h if any XS files use it
	if ( $self->find_ppport->in( $self->dist_dir ) ) {
		Devel::PPPort::WriteFile( $self->dist_ppport );
	}

	# Copy in author tests as needed
	unless ( -f $self->dist_99_author ) {
		foreach my $xt ( qw{ pod.t pmv.t } ) {
			next if -f catfile( $self->dist_xt, $xt );
			$self->copy(
				catfile( $self->shared_dir, $xt ),
				catfile( $self->dist_xt,     $xt ),
			);
		}
	}

	# Create the README file
	unless ( -f $self->dist_readme ) {
		my $dist_readme = $self->dist_readme;
		my $module_pod = -f $self->module_pod ? $self->module_pod : $self->module_pm;
		$self->shell(
			$self->bin_cat,
			$module_pod,
			"| pod2text >",
			$dist_readme,
			"Error while generating README file '$dist_readme'",
		)
	}

	# Localise all newlines in text files
	$self->file_localize->localize( $self->dist_dir );
	
	# Check for various unsafe things in Makefile.PL
	if ( $self->makefile_pl ) {
		if ( $self->makefile_pl =~ /use inc::Module::Install/ ) {
			if ( $self->makefile_pl =~ /\bauto_install\b/ ) {
				$self->error("Makefile.PL contains dangerous auto_install");
			}
		} else {
			unless ( $self->makefile_pl =~ /use strict/ ) {
				$self->error("Makefile.PL does not use strict");
			}
			unless ( $self->makefile_pl =~ /(?:use|require) \d/ ) {
				$self->error("Makefile.PL does not declare a minimum Perl version");
			}
		}
	}

	# Check file permissions
	foreach my $file ( sort $self->find_0644->in( $self->dist_dir ) ) {
		my $mode = (stat($file))[2] & 07777;
		next if $mode == 0644;
		$self->shell(
			$self->bin_chmod,
			'0644',	
			$file,
			"Error setting $file to 0644 permissions",
		);
	}

	# Make sure exe files are marked with executable permissions
	if ( $self->find_executable->in( $self->dist_dir ) ) {
		$self->error("Found at least one .exe file without -x unix permissions");
	}

	# Check the Changes file
	unless ( $self->no_changes ) {
		# Read in the Changes file
		unless ( -f $self->dist_changes ) {
			$self->error("Distribution does not have a Changes file");
		}
		unless ( open( CHANGES, $self->dist_changes ) ) {
			$self->error("Failed to open Changes file");
		}
		my @lines = <CHANGES>;
		close CHANGES;
		unless ( @lines >= 3 ) {
			$self->error("Changes file is empty or too small");
		}

		# The Changes version should be the first thing on the third line
		my $current   = $lines[2];
		my ($version) = split /\s+/, $current;
		unless ( $version =~ /[\d\._]{3}/ ) {
			$self->error(
				"Failed to find current version, or too short, in '%2'",
				$current,
			);
		}

		# Does it match the version in the main module
		unless ( $version eq $self->dist_version ) {
			$self->error(
				"Version in Changes file (%s) does not match module version (%s)",
				$version,
				$self->dist_version,
			);
		}
	}

	# Check that the main module documentation Copyright is the current year
	unless ( $self->no_copyright ) {
		# Read the file
		unless ( open( MODULE, $self->module_doc ) ) {
			$self->error(
				"Failed to open '%s'",
				$self->module_doc,
			);
		}
		my @lines = <MODULE>;
		close MODULE;

		# Look for the current year
		my $year = 1900 + (localtime time)[5];
		unless ( grep { /copyright/i and /$year/ } @lines ) {
			$self->error("Missing Copyright, or does not refer to current year");
		}

		# Merge the module to a single string
		my $merged = join "\n", @lines;
		unless ( $self->no_rt ) {
			my $dist_name = $self->dist;
			unless ( $merged =~ /L\<http\:\/\/rt\.cpan\.org\/.+?=([\w-]+)\>/ ) {
				$self->error("Failed to find a link to the public RT queue");
			}
			unless ( $dist_name eq $1 ) {
				$self->error("Expected a public link to $dist_name RT queue, but found a link to the $1 queue");
			}
		}
	}

	# Touch all files to correct any potential time skews
	foreach my $file ( $self->find_files->in( $self->dist_dir ) ) {
		$self->shell(
			$self->bin_touch,
			$file,
			"Error while touching $file to prevent clock skew",
		);
	}

	return;
}

sub build {
	my $self = shift;

	# Prevent environment variables from outside this script
	# infecting the way we build things inside here.
	local $ENV{AUTOMATED_TESTING} = '';
	local $ENV{RELEASE_TESTING}   = '';

	# Run either of the build protocols
	if ( $self->makefile_pl ) {
		$self->build_make;

	} elsif ( $self->build_pl ) {
		$self->build_perl;

	} else {
		$self->error("Module does not have a Makefile.PL or Build.PL");
	}

	# Double check that the build produced a tarball where we expect it to be
	unless ( -f $self->dist_tardist ) {
		$self->error(
			"Failed to create tardist at '%s'",
			$self->dist_tardist,
		);
	}

	return;
}

sub build_make {
	my $self = shift;

	# Create the Makefile and MANIFEST
	$self->build_makefile;
	$self->build_makefile_manifest;

	unless ( $self->no_test ) {
		# Test the distribution normally
		$self->shell(
			$self->bin_make,
			'disttest',
			'disttest failed',
		);

		# Test with AUTOMATED_TESTING on
		SCOPE: {
			local $ENV{AUTOMATED_TESTING} = 1;
			$self->build_makefile;
			$self->shell(
				$self->bin_make,
				"disttest",
				'disttest failed',
			);
		}

		# Test with RELEASE_TESTING on
		SCOPE: {
			local $ENV{RELEASE_TESTING} = 1;
			$self->build_makefile;
			$self->shell(
				$self->bin_make,
				"disttest",
				'disttest failed',
			);
		}

		# Test with RELEASE_TESTING and root permissions.
		# This catches bad test script assumptions in modules related
		# to files and permissions (File::Remove, File::Flat etc).
		SCOPE: {
			local $ENV{RELEASE_TESTING}   = 1;
			$self->sudo(
				qw{ perl Makefile.PL },
				'Error while creating Makefile',
			);
			$self->sudo(
				$self->bin_make,
				"disttest",
				'disttest failed',
			);

			# Clean up leftover root files and rebuild from scratch
			$self->build_realclean;
			$self->build_makefile;
			$self->build_makefile_manifest;

			# Run the test suite one last time to make sure we
			# didn't break anything.
			$self->sudo(
				$self->bin_make,
				"disttest",
				'disttest failed',
			);

			# Clean up the leftover root files again
			$self->build_realclean;
		}
	}

	# Create the Makefile and MANIFEST
	$self->build_makefile;
	$self->build_makefile_manifest;

	# Build the tardist
	$self->shell(
		$self->bin_make,
		"tardist",
		'Error making distribution tarball',
	);

	return;
}

sub build_makefile {
	my $self = shift;

	# Execute Makefile.PL with the current environment's perl
	$self->shell(
		qw{ perl Makefile.PL },
		'Error while creating Makefile',
	);

	# Add the build-system-specific elements to the META.yml
	my $meta = YAML::Tiny->read( $self->dist_meta_yml );
	return unless defined $meta;

	# Add the resources
	my $save = 0;
	unless ( $meta->[0]->{resources} ) {
		$meta->[0]->{resources} = {};
		$save = 1;
	}
	unless ( $meta->[0]->{resources}->{repository} ) {
		$meta->[0]->{resources}->{repository} = $self->dist_resource_repository;
		$save = 1;
	}
	if ( $save ) {
		$meta->write( $self->dist_meta_yml );
	}

	return;
}

sub build_makefile_manifest {
	my $self = shift;

	$self->shell(
		$self->bin_make,
		"manifest",
		"Error while creating the MANIFEST",
	);	
}

sub build_realclean {
	my $self = shift;

	# Clean up the distribution (always with root)
	$self->sudo(
		$self->bin_make,
		"realclean",
		'sudo make clean failed',
	);
	$self->remove( $self->dist_manifest );
}

sub build_perl {
	my $self = shift;

	# Create the Build file
	$self->shell(
		qw{ perl Build.PL },
		'Error while creating Makefile',
	);

	# Create the MANIFEST file
	$self->shell(
		"./Build",
		"manifest",
		'Error while creating the MANIFEST',
	);

	unless ( $self->no_test ) {
		# Test the distribution normally
		$self->shell(
			qw{ ./Build disttest },
			'disttest failed',
		);
	}

	# Build the tardist
	$self->shell(
		qw{ ./Build dist },
		'Error making distribution tarball',
	);

	return;
}

sub upload {
	my $self = shift;

	my $pauseid = $self->prompt("PAUSEID:");
	unless (_STRING($pauseid) and $pauseid =~ /^[A-Z]{3,}$/) {
		$self->error("Missing or invalid PAUSEID");
	}

	my $password = $self->password("Password:");
	unless (_STRING($password) and $password =~ /^\S{5,}$/) {
		$self->error("Missing or invalid CPAN password");
	}

	# Execute the upload to CPAN
	CPAN::Uploader->upload_file( $self->dist_tardist, {
		user     => $pauseid,
		password => $password,
	});
}





######################################################################
# Content and Scanning Methods

# Get the main github repository url for this release
sub dist_resource_repository {
	my $self = shift;

	return join( '',
		"https://github.com/",
		$self->github->username,
		$self->github->repository,
		'.git',
	);
}

sub makefile_pl {
	my $self = shift;
	unless ( defined $self->{makefile_pl} ) {
		my $file = $self->dist_makefile_pl;
		return undef unless -f $file;
		$self->{makefile_pl} = File::Slurp::read_file($file);
	}
	return $self->{makefile_pl};
}

sub build_pl {
	my $self = shift;
	unless ( defined $self->{build_pl} ) {
		my $file = $self->dist_build_pl;
		return undef unless -f $file;
		$self->{build_pl} = File::Slurp::read_file($file);
	}
	return $self->{build_pl};
}

sub module_doc {
	my $self = shift;
	unless ( exists $self->{module_doc} ) {
		if ( -f $self->module_pod ) {
			$self->{module_doc} = $self->module_pod;
		} else {
			$self->{module_doc} = $self->module_pm;
		}
	}
	return $self->{module_doc};
}

sub module_version {
	my $self = shift;
	unless ( $self->{module_version} ) {
		my $file    = $self->module_pm;
		my $version = Module::Extract::VERSION->parse_version_safely($file);
		unless ( $version and $version ne 'undef' ) {
			return undef;
		}
		$self->{module_version} = $version;
	}
	return $self->{module_version};
}

sub find_ppport {
	File::Find::Rule->name('*.xs')->file->grep(qr/\bppport\.h\b/);
}

sub find_files {
	File::Find::Rule->file;
}

sub find_0644 {
	File::Find::Rule->name(qw{
		Changes
		Makefile.PL
		META.yml
		*.t
		*.pm
		*.pod
	} )->file;
}

sub find_executable {
	File::Find::Rule->name('*.exe')->not_executable->file;
}

sub find_localize {
	File::Find::Rule->file->not_binary->writable;
}

sub file_localize {
	File::LocalizeNewlines->new(
		filter  => $_[0]->find_localize,
		verbose => 1,
	);
}





######################################################################
# Paths and Files

sub dist {
	my $self   = shift;
	my $dist = $self->module;
	$dist =~ s/::/-/g;
	return $dist;
}

sub dist_dir {
	curdir();
}

sub dist_tardist {
	$_[0]->dist_file;
}

sub dist_file {
	$_[0]->dist . '-' . $_[0]->dist_version . '.tar.gz';
}

sub dist_version {
	$_[0]->module_version;
}

sub dist_makefile_pl {
	'Makefile.PL';
}

sub dist_build_pl {
	'Build.PL';
}

sub dist_changes {
	'Changes';
}

sub dist_license {
	'LICENSE';
}

sub dist_readme {
	'README';
}

sub dist_meta_yml {
	'META.yml';
}

sub dist_manifest {
	'MANIFEST';
}

sub dist_manifest_skip {
	'MANIFEST.SKIP';
}

sub dist_manifest_add {
	'MANIFEST.SKIP.add';
}

sub dist_ppport {
	'ppport.h';
}

sub dist_t {
	't';
}

sub dist_data {
	catdir('t', 'data');
}

sub dist_99_author {
	catfile('t', '99_author.t');
}

sub dist_xt {
	'xt';
}

sub module_pm {
	catfile( 'lib', $_[0]->module_subpath ) . '.pm';
}

sub module_pod {
	catfile( 'lib', $_[0]->module_subpath ) . '.pod';
}

sub module_subpath {
	catdir( split /::/, $_[0]->module );
}

sub shared_manifest_skip {
	catfile( $_[0]->shared_dir, 'MANIFEST.SKIP' );
}

sub shared_license {
	catfile( $_[0]->shared_dir, 'LICENSE' );
}

sub shared_dir {
	File::ShareDir::dist_dir('ADAMK-Release')
	or $_[0]->error("Failed to find share directory");	
}




######################################################################
# Support Methods

# Is a particular program installed, and where
sub which {
	my $self    = shift;
	my $program = shift;
	my ($location) = (`which $program`);
	chomp $location;
	unless ( $location ) {
		$self->error("Can't find the required program '$program'. Please install it");
	}
	unless ( -r $location and -x $location ) {
		$self->error("The required program '$program' is installed, but I do not have permission to read or execute it");
	}
	return $location;
}

sub copy {
	my $self = shift;
	my $from = shift;
	my $to   = shift;
	File::Flat->copy( $from => $to ) and return 1;
	$self->error("Failed to copy '$from' to '$to'");
}

sub move {
	my $self = shift;
	my $from = shift;
	my $to   = shift;
	File::Flat->copy( $from => $to ) and return 1;
	$self->error("Failed to move '$from' to '$to'");
}

sub remove {
	my $self = shift;
	my $path = shift;
	if ( -e $path ) {
		$self->sudo(
			"rm -rf $path",
			"Failed to remove '$path'"
		);
	}
	return 1;
}

sub sudo {
	my $self    = shift;
	my $message = pop @_;
	my $cmd     = join ' ', @_;
	my $env     = $self->env(
		ADAMK_RELEASE     => 1,
		RELEASE_TESTING   => $ENV{RELEASE_TESTING}   ? 1 : 0,
		AUTOMATED_TESTING => $ENV{AUTOMATED_TESTING} ? 1 : 0,
	);
	print "> (sudo) $cmd\n" if $self->verbose;
	my $sudo = $self->bin_sudo;
	my $rv   = ! system( "$sudo bash -c '$env $cmd'" );
	if ( $rv or ! @_ ) {
		return $rv;
	}
	$self->error($message);
}

sub shell {
	my $self    = shift;
	my $message = pop @_;
	my $cmd     = join ' ', @_;
	my $env     = $self->env(
		ADAMK_RELEASE     => 1,
		RELEASE_TESTING   => $ENV{RELEASE_TESTING}   ? 1 : 0,
		AUTOMATED_TESTING => $ENV{AUTOMATED_TESTING} ? 1 : 0,
	);
	print "> $cmd\n" if $self->verbose;
	my $rv = ! system( "$env $cmd" );
	if ( $rv or ! @_ ) {
		return $rv;
	}
	$self->error($message);
}

sub env {
	my $self = shift;
	my %env  = @_;
	join ' ', map { "$_=$env{$_}" } sort keys %env;
}

sub error {
	my $self    = shift;
	my $message = sprintf(shift, @_);
	Carp::croak($message);
}

sub prompt {
	my $self = shift;
	return IO::Prompt::Tiny::prompt(@_);
}

sub password {
	my $self     = shift;
	my $password = undef;
	if ( defined $_[0] ) {
		print "$_[0] ";
	}
	eval {
		Term::ReadKey::ReadMode('noecho');
		$password = <STDIN>;
	};
	Term::ReadKey::ReadMode(0);
	return undef if not defined $password;
	chomp($password);
	return $password;
}

1;

__END__

=head1 NAME

ADAMK::Release - 

=head1 DESCRIPTION

C<ADAMK::Release> is the backend behind the C<adamk-release> script that
is used to build distribution tarballs for modules with the minimalist
repository style.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
