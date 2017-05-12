########################################################################
                    package My::Build::Linux;
########################################################################

use strict;
use warnings;
use parent 'My::Build';
use File::ShareDir;

# We don't need any extra args for pure Linux builds, but this may be
# overridden by derived classes
sub extra_config_args { '' }

sub make_command { 'make' }

sub install_to_prefix {
	my ($self, $prefix) = @_;
	
	return if $self->notes('build_state') eq $prefix;
	
	$self->my_clean;
	
	# Get the system-specific make command
	my $make = $self->make_command;
	
	# move into the source directory and perform configure, make, and install
	chdir 'src';
	
	# Add -fPIC if it's in our Perl Config's cccdlflags
	use Config;
	$ENV{CFLAGS} = '' unless $ENV{CFLAGS};  # Avoid undef warnings
	$ENV{CFLAGS} .= ' -fPIC'
		if $Config{cccdlflags} =~ /-fPIC/ and $ENV{CFLAGS} !~ /-fPIC/;
	$ENV{CFLAGS} .= ' -fpic'
		if $Config{cccdlflags} =~ /-fpic/ and $ENV{CFLAGS} !~ /-fpic/;
	
	# clean followed by a normal incantation
	my $extra_args = $self->extra_config_args;
	system("./configure --prefix=$prefix $extra_args")
		and die 'tcc build failed at ./configure';
	system($make)
		and die 'tcc build failed at make';
	system($make, 'install')
		and die 'tcc build failed at make install';
	
	# Move back to the root directory
	chdir '..';
	
	# Record the current build state so we don't build more than necessary.
	$self->notes('build_state', $prefix);
}

use Cwd;
sub ACTION_code {
	my $self = shift;
	$self->notes('build_state', '') unless defined $self->notes('build_state');
	
	# Build an absolute prefix to our (local) sharedir, build and install
	my $prefix = File::Spec->catdir(getcwd(), 'share');
	$self->install_to_prefix($prefix);
	
	$self->SUPER::ACTION_code;
}

sub my_clean {
	my $self = shift;
	return unless -f 'src/config.mak';
	
	# Get the system-specific make command
	my $make = $self->make_command;
	
	chdir 'src';
	system($make, 'clean');
	chdir '..';
}

use File::Path;
sub ACTION_install {
	my $self = shift;
	
	# For unixish systems, we must re-build with the new prefix so that all of
	# the baked-in paths are correct. I just wanna say this:
	#my $prefix = File::ShareDir::dist_dir('Alien-TinyCCx');
	# Unfortunately, this won't work because File::ShareDir expects the
	# folder to already exist.
	
	# Instead, I copy code from Alien::Base::ModuleBuild to calculate the
	# sharedir location by-hand:
	my $prefix = File::Spec->catdir($self->install_destination('lib'),
		qw(auto share dist Alien-TinyCCx));
	
	# Completely rebuild (and install) the compiler with the new prefix
	File::Path::make_path($prefix);
	$self->install_to_prefix($prefix);
	
	# Proceed with the rest of the install
	$self->SUPER::ACTION_install;
}

### ucontext location detection patch ###

use File::Temp qw/ tempfile /;
use Config;

# Header file test
sub try_include_file {
	my $lib_name = shift;
	my ($out_fh, $out_filename) = tempfile(UNLINK => 1, SUFFIX => '.c');
	print $out_fh "#include <$lib_name>\nint main() { return 1;}";
	close $out_fh;
	return system("$Config{cc} $out_filename") == 0 ? $lib_name : undef;
}

if (-f 'src/tcc.h') {
	# Now patch tcc.h for the proper ucontext location. Put the detection
	# code inside the patch snippet so that the tests only run once.
	My::Build::apply_patches('src/tcc.h',
		qr/#\s*include.*ucontext/ => sub {
			my ($in_fh, $out_fh, $line) = @_;
	
			# Find the proper include location for ucontext.h
			my $ucontext_include = try_include_file('sys/ucontext.h')
				|| try_include_file('ucontext.h')
				|| die "Unable to locate ucontext!";
			# Clean up after compilation tests.
			unlink 'a.out';
			
			print $out_fh "#include <$ucontext_include>\n";
			return 1;
		},
	);

#### IGNORING FOR NOW. I think this needs to be applied, but I don't
#### have any test reports from Cygwin to tell me what to do.
#	# Apply patch to keep Cygwin happy
#	My::Build::apply_patches('src/tccrun.c',
#		qr/uc->uc_mcontext\.mc_r[bi]p;/ => sub {
#			my ($in_fh, $out_fh, $line) = @_;
#			
#			# Keep original code
#			print $out_fh $line;
#			
#			# Check if these changes have already been applied. The
#			# next line is either "#else" (which means not applied)
#			# or "#elif ..." (which means applied)
#			my $next_line = <$in_fh>;
#			if ($next_line =~ /elif/) {
#				# Nothing to do; return indicating we've handled the
#				# line.
#				print $out_fh $next_line;
#				return 1;
#			}
#			
#			# Apply a few preprocessor if/else lines, too
#			if ($line =~ /paddr/) {
#				print $out_fh <<'PADDR_PATCH';
##elif defined(__CYGWIN__)
#        *paddr = uc->uc_mcontext.rip;
#PADDR_PATCH
#			}
#			elsif ($line =~ /fp/) {
#				print $out_fh <<'FP_PATCH';
##elif defined(__CYGWIN__)
#        fp = uc->uc_mcontext.rbp;
#FP_PATCH
#			}
#			else {
#				die "Unexpected patch line:\n$line";
#			}
#			print $out_fh $next_line;
#			
#			# patcher does *not* need to include this line, we've
#			# already done that.
#			return 1;
#		},
#	);
	
	# Turn off stack protection
	my $stack_protector_removed;
	My::Build::apply_patches('src/Makefile',
		qr/fno-stack-protector/ => sub {
			$stack_protector_removed = 1;
			return;
		},
	);
	My::Build::apply_patches('src/Makefile',
		qr/else # not GCC/ => sub {
			my ($in_fh, $out_fh, $line) = @_;
			print $out_fh "CFLAGS+=-fno-stack-protector\n"
				unless $stack_protector_removed;
			return;
		},
	);
}

1;
