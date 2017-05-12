package Alien::LIBSVM::ModuleBuild;

use strict;
use warnings;

use parent 'Alien::Base::ModuleBuild';
use File::Copy "cp";
use File::Path qw(make_path);
use File::chmod;

sub alien_do_commands {
	my ($self, $phase) = @_;

	if( $^O eq 'MSWin32' && $phase eq 'build' ) {
		## nothing to build on Windows
		return 1;
	} else {
		$self->SUPER::alien_do_commands($phase);
	}
}

sub main::alien_patch {
	my $makefile = 'Makefile';
	my $makefile_new = "$makefile.tmp";

	open my $in,  '<', $makefile;
	open my $out, '>', $makefile_new;

	while(<$in>) {
		if(/^SHVER = 2/) {
			# real version is 3.x
			print $out <<END
SHVER = 3
END
		} else {
			print $out $_;
		}
	}
	close $in;
	close $out;
	unlink $makefile;
	rename $makefile_new, $makefile;
}

sub main::install_helper {
	my $dir = $ARGV[0];

	my (@libs, @headers, @bins);
	my @bin_names = qw(svm-predict svm-scale svm-train);
	if( $^O eq 'MSWin32' ) {
		@libs = ( File::Spec->catfile( qw(windows libsvm.dll) ) );
		@headers = ( 'svm.h' );
		@bins = map { File::Spec->catfile( 'windows', "$_.exe" ) } @bin_names;
	} else {
		@libs = ( 'libsvm.so.3', 'libsvm.a' );
		@headers = ( 'svm.h' );
		@bins = @bin_names;
	}

	my ($lib_dir, $header_dir, $bin_dir) =
		map { File::Spec->catfile( $dir, $_ ) }
		qw(lib include bin);

	my @filesys = (
		{ to => $lib_dir, files => \@libs, symlink => { 'libsvm.so' => 'libsvm.so.3' } },
		{ to => $header_dir, files => \@headers },
		{ to => $bin_dir, files => \@bins, exec => 1 },
	);

	local $File::chmod::UMASK = 0;
	for my $type (@filesys) {
		make_path $type->{to};
		for my $file (@{ $type->{files} }) {
			cp( $file, $type->{to} ); # cp keeps permissions
			chmod 'a+x', File::Spec->catfile( $type->{to}, $file ) if exists $type->{exec};
		}
		if( $^O ne 'MSWin32' && exists $type->{symlink} ) {
			# NOTE we assume symlink exists on non-MSWin32 systems
			while( my ($k, $v) = each %{  $type->{symlink} } ) {
				symlink(
					File::Spec->catfile( $type->{to}, $v ),
					File::Spec->catfile( $type->{to}, $k ) );
			}
		}
	}
}

1;
