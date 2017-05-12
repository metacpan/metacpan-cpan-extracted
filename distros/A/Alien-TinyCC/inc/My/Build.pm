########################################################################
                       package My::Build;
########################################################################

use strict;
use warnings;
use parent 'Module::Build';

sub ACTION_build {
	my $self = shift;
	
	mkdir 'share';
	
	$self->SUPER::ACTION_build;
}

use File::Path;
sub ACTION_clean {
	my $self = shift;
	
	File::Path::remove_tree('share');
	$self->notes('build_state', '');
	
	# Call system-specific cleanup code
	$self->my_clean;
	
	# Call base class code
	$self->SUPER::ACTION_clean;
}

use File::Copy;
use File::Spec;
sub ACTION_devsetup {
	my $self = shift;
	system qw(git submodule init);
	system qw(git submodule update);
	my $hook_filename = File::Spec->catfile(qw<.git hooks pre-commit>);
	copy 'git-pre-commit-hook.pl' => $hook_filename;
	chmod 0755, $hook_filename;
}

# Reset the tcc source code. This only makes sense if the person has
# src checked out as a git submodule, but then again, the actions for
# which this exists are generally considered author actions anyway.
sub reset_src {
	chdir 'src';
	system qw( git reset --hard HEAD );
	chdir '..';
}

sub ACTION_devclean {
	my $self = shift;
	reset_src;
	$self->ACTION_clean;
}

sub ACTION_devrealclean {
	my $self = shift;
	reset_src;
	$self->ACTION_realclean;
}

# This one's an author action, so I assume they have git and have properly
# configured.
sub ACTION_dist {
	my $self = shift;
	reset_src;
	$self->SUPER::ACTION_dist;
}

# This one's an author action, so I assume they have git and have properly
# configured.
sub ACTION_distdir {
	my $self = shift;
	reset_src;
	$self->SUPER::ACTION_distdir;
}

# This one's an author action, so I assume they have git and have properly
# configured.
sub ACTION_disttest {
	my $self = shift;
	reset_src;
	$self->SUPER::ACTION_disttest;
}

sub apply_patches {
	my ($filename, @patches) = @_;
	
	# make the file read-write (and executable, but that doesn't matter)
	chmod 0700, $filename;
	
	open my $in_fh, '<', $filename
		or die "Unable to open $filename for patching!";
	open my $out_fh, '>', "$filename.new"
		or die "Unable to open $filename.new for patching!";
	LINE: while (my $line = <$in_fh>) {
		# Apply each basic test regex, and call the function if it matches
		for (my $i = 0; $i < @patches; $i += 2) {
			if ($line =~ $patches[$i]) {
				my $next_line = $patches[$i+1]->($in_fh, $out_fh, $line);
				next LINE if $next_line;
			}
		}
		print $out_fh $line;
	}
	
	close $in_fh;
	close $out_fh;
	unlink $filename;
	rename "$filename.new" => $filename;
	
	# make sure it's executable; we may be patching ./configure
	chmod 0700, $filename;
}

1;
