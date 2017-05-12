package Alien::LibMagic::ModuleBuild;

use strict;
use warnings;

use parent 'Alien::Base::ModuleBuild';
use Archive::Extract;
use File::Copy;
use File::Spec;
use Module::Load;
use File::chdir;

sub alien_library_destination {
	my ($self) = @_;
	my $dest = $self->SUPER::alien_library_destination;
	if( $^O eq 'MSWin32' ) {
		$dest =~ s,\\,/,g;
	}
	return $dest;
}

sub alien_do_commands {
	my ($self, $phase) = @_;
	my $dir = $self->config_data( 'working_directory' );

	if( $^O eq 'MSWin32' ) {
		load 'Alien::MSYS';
		my $extract_to = $phase eq 'build'
			? $dir
			: $self->alien_library_destination;


		my $inc_dir = File::Spec->catfile( $dir, '..', '..', 'inc' );
		my @bins = qw( libgnurx-0.dll libgnurx.dll.a libregex.a );
		if( $phase eq 'build' ) {
			my $archive_file = File::Spec->catfile( $inc_dir, 'mingw-libgnurx-2.5.1-src.tar.gz' );
			my $e = Archive::Extract->new( archive => $archive_file );
			$e->extract( to => $extract_to );
			my $patch_file = File::Spec->catfile( $inc_dir, 'patch\mingw-libgnurx-2.5.1' );
			my $gnurx_dir = File::Spec->catfile( $extract_to, "mingw-libgnurx-2.5.1");
			{
				local $CWD = $gnurx_dir;
				Alien::MSYS::msys( sub  {
					system(qw(patch --binary -i), $patch_file);
					system(qw(sh .\configure));
					system(qw(make));
					move($_, $extract_to ) for ( @bins, 'regex.h' );
					system(qw(make distclean));
				} );
			}

			# make libgnurx available to libfile build
			$ENV{LDFLAGS} //= " "; $ENV{CPPFLAGS} //= " "; # space required on windows
			(my $extract_to_forward = $extract_to) =~ s,\\,/,g;
			#$extract_to_forward =~ s,(\w):/,/$1/,; # drive letter: C:/ -> /C/
			$ENV{LDFLAGS} .= " -L$extract_to_forward";
			$ENV{CPPFLAGS} .= " -I$extract_to_forward";
			$ENV{PATH} .= ";$extract_to_forward";
			print "$ENV{LDFLAGS}\n$ENV{CPPFLAGS}\n$ENV{PATH}\n";
		} elsif( $phase eq 'install' ) {
			my $target = $self->SUPER::alien_library_destination;
			for my $bin (@bins) {
				my $under = ( $bin =~ /\.dll$/ ) ? "bin" : "lib";
				my $target_dir = File::Spec->catfile($target, $under);
				copy(File::Spec->catfile($dir, $bin), $target_dir );
			}
		}
		Alien::MSYS::msys( sub  {
			$self->SUPER::alien_do_commands($phase);
		} );
	} else {
		$self->SUPER::alien_do_commands($phase);
	}
}

1;
