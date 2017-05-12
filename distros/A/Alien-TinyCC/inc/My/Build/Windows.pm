########################################################################
                   package My::Build::Windows;
########################################################################

use strict;
use warnings;
use parent 'My::Build';

sub ACTION_code {
	my $self = shift;
	
	require File::Copy::Recursive;
	
	if (not $self->notes('build_state')) {
		# move into the source directory and invoke the custom Windows build
		chdir 'src\\win32';
		system('build-tcc.bat');
		chdir '..\\..';
		
		# check if there was a mishap:
		$ENV{ERRORLEVEL} and die 'build-tcc.bat failed';
		
		# Copy the files to the distribution's share dir
		File::Copy::Recursive::rcopy_glob('src\\win32\\*' => 'share\\');
		
		# Note that we've built it.
		$self->notes('build_state', 'built');
	}
	
	$self->SUPER::ACTION_code;
}

sub my_clean {}

# Figure out if this is a 64-bit system:
use Config;
my $is_64_bit = ($Config{archname} =~ /^MSWin32-(.*?)-/ and $1 eq 'x64');

# Patch the build batch file
My::Build::apply_patches('src\\win32\\build-tcc.bat',
	# Special-casing for 32 or 64 bit processors is just better handled by
	# modifications based on Perl-side config data. This one handles identifying
	# 64-bit builds.
	qr/goto x86_64/ => sub {
		# Found the line that's supposed to jump ahead to :x86_64 if we have a
		# 64-bit architecture. Let's either get rid of these, for 32 bit systems,
		# or get rid of the 32-bit stuff for 64-bit systems.
		my ($in_fh, $out_fh, $line) = @_;
		
		# Chew through the not-great 64-bit detection checks
		$line = <$in_fh>;
		$line = <$in_fh> while $line =~ /goto x86_64/;
		
		# If we are 64-bit, chew through everything until we get to the goto
		# label. Then skip to the next line.
		if ($is_64_bit) {
			$line = <$in_fh> until $line =~ /:x86_64/;
		}
		else {
			print $out_fh $line;
		}
		
		# All done; skip to next line
		return 1;
	},
	qr/:x86_64/ => sub {
		my ($in_fh, $out_fh, $line) = @_;
		# We can only have detected this label if it was not eaten by the
		# 64-bit detection code. Remove this and everything up to the tools
		# label
		die "64 bit machines shouldn't have :x86_64 label after preprocessing!"
			if $is_64_bit;
		$line = <$in_fh> until $line =~ /:tools/;
		print $out_fh $line;
		return 1;
	},
	qr/\@set CC=/ => sub {
		my ($in_fh, $out_fh, $line) = @_;
		# Replace the compiler name with the one used by Perl itself:
		$line =~ s/CC=\S+/CC=$Config{cc}/;
		print $out_fh $line;
		return 1;
	},
);

1;
