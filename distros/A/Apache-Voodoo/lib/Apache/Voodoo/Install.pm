############################################################################
#
# Apache::Voodoo::Install - Base package for Apache::Voodoo::Install::* objects.
#
# This package provides some basic common methods needed by all the "real work"
# Apache::Voodoo::Install::* objects.
#
###########################################################################
package Apache::Voodoo::Install;

$VERSION = "3.0200";

use strict;
use warnings;

use Data::Dumper;

################################################################################
# Sets / unsets the 'pretend' run mode
################################################################################
sub pretend {
	my $self = shift;
	$self->{'pretend'} = shift;
}

sub _printer {
	my $self  = shift;
	my $level = shift;

	if ($self->{'verbose'} >= $level) {
		foreach (@_) {
			if (ref($_)) {
				print Dumper $_;
			}
			else {
				print $_,"\n";
			}
		}
	}
}

sub mesg {
	my $self = shift;
	$self->_printer(0,@_);
}

sub info {
	my $self = shift;
	$self->_printer(1,@_);
}

sub debug {
	my $self = shift;
	$self->_printer(2,@_);
}


sub make_symlink {
	my $self    = shift;
	my $source  = shift;
	my $target  = shift;

	my $pretend = $self->{'pretend'};

	$self->info("- Checking symlink $target");

	lstat($target);
	if (-e _ && -l _ ) {
		# it's there and it's a link, let's make sure it points to the correct place.
		my @ss = stat($target);
		my @ts = stat($source);
		if ($ss[1] != $ts[1]) {
			# inode's are different.
			$pretend || unlink($target)          || $self->{ignore} || die "Can't remove bogus link: $!";
			$pretend || symlink($source,$target) || $self->{ignore} || die "Can't create symlink: $!";
			$self->debug(": invalid, fixed");
		}
		else {
			$self->debug(": ok");
		}
	}
	else {
		# not there, or not a link.
		# make sure the path is valid
		my $p;
		my @p = split('/',$target);
		pop @p; # throw away filename
		foreach my $d (@p) {
			$p .= '/'.$d;
			unless (-e $p && -d $p) {
				$pretend || mkdir ($p,0755) || $self->{ignore} || die "Can't create directory: $!";
			}
		}

		$pretend || unlink($target);	# in case it was there.

		$pretend || symlink($source,$target) || $self->{ignore} || die "Can't create symlink: $!";
		$self->debug(": missing, created");
	}
}

sub make_writeable_dirs {
	my $self = shift;
	my @dirs = shift;

	my $pretend = $self->{'pretend'};
	my $uid     = $self->{'apache_uid'};
	my $gid     = $self->{'apache_gid'};

	foreach my $dir (@dirs) {
		$self->info("- Checking directory $dir");
		stat($dir);
		if (-e _ && -d _ ) {
			$self->debug(": ok");
		}
		else {
			$pretend || mkdir($dir,770) || $self->{ignore} || die "Can't create directory $dir: $!";
			$self->debug(": created");
		}
		$self->info("- Making sure the $dir directory is writable by apache");
		$pretend || chown($uid,$gid,$dir) || $self->{ignore} || die "Can't chown directory: $!";
		$pretend || chmod(0770,$dir)      || $self->{ignore} || die "Can't chmod directory: $!";
		$self->debug(": ok");
	}
}

sub make_writeable_files {
	my $self  = shift;
	my @files = shift;

	my $pretend = $self->{'pretend'};
	my $uid     = $self->{'apache_uid'};
	my $gid     = $self->{'apache_gid'};

	foreach my $file (@files) {
		$self->info("- Checking file $file");
		if (-e $file) {
			$self->debug(": ok");
		}
		else {
			$pretend || (system("touch $file") && ($self->{ignore} || die "Can't create file: $!"));
			$self->debug(": created");
		}
		$self->info("- Making sure the $file directory is writable by apache");
		$pretend || chown($uid,$gid,$file) || $self->{ignore} || die "Can't chown file: $!";
		$pretend || chmod(0600,$file)      || $self->{ignore} || die "Can't chmod file: $!";
		$self->debug(": ok");
	}
}

# In a pine box somewhere De Morgan is either spinning violently, or applauding.  We're not
# sure which.

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
