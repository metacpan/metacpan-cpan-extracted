package Alien::pdf2json::ModuleBuild;

use strict;
use warnings;

use parent 'Alien::Base::ModuleBuild';
use Archive::Extract;
use File::Copy;
use File::chdir;
use File::Spec;

sub alien_do_commands {
  my ($self, $phase) = @_;
	my $dir = $self->config_data( 'working_directory' );
	my $bin_dir = File::Spec->catfile( $dir, 'bin' );

	if( $phase eq 'build' ) {
			mkdir $bin_dir; # make ./bin/ in working directory
	}
	if( $self->is_windowsish ) {
		if( $phase eq 'build' ) {
			# extract ../inc/pdf2json-0.68-win32.zip
			my $win32_build_zip = glob File::Spec->catfile( $dir, '..', 'inc', '*-win32.zip' );
			my $e = Archive::Extract->new( archive => $win32_build_zip );
			$e->extract; 

			# move from ./pdf2json.exe to ./bin/pdf2json.exe
			move( File::Spec->catfile( $dir, 'pdf2json.exe'), File::Spec->catfile( $bin_dir,'pdf2json.exe') );

			return 1;
		} elsif(  $phase eq 'install' ) {
			my $target_bin = File::Spec->catfile( $self->alien_library_destination, 'bin' );
			mkdir $target_bin;

			my $src_pdf2json = File::Spec->catfile( $bin_dir, 'pdf2json.exe' );
			my $target_pdf2json = File::Spec->catfile( $target_bin, 'pdf2json.exe' );

			copy( $src_pdf2json, $target_pdf2json );
			return 1;
		} else {
			$self->SUPER::alien_do_commands($phase);
		}
	} else {
		my $ret = $self->SUPER::alien_do_commands($phase);
		if( $phase eq 'build' ) {
			# after build
			my $pdf2json_src = File::Spec->catfile( $dir, 'src', 'pdf2json' );
			my $pdf2json_tgt = File::Spec->catfile( $bin_dir, 'pdf2json' );

			# needed for test to pass
			copy $pdf2json_src, $pdf2json_tgt;
			chmod '0755', $pdf2json_tgt; # rwxr-xr-x
		}
		return $ret;
	}
}

1;
