################################################################################
#
# Apache::Voodoo::Install::Post
#
# Handles common post site setup tasks. This object is used by Voodoo internally.
#
################################################################################
package Apache::Voodoo::Install::Post;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Install");

use Apache::Voodoo::Constants;

use Config::General qw(ParseConfig);

sub new {
	my $class = shift;
	my %params = @_;

	my $self = {%params};

	my $ac = Apache::Voodoo::Constants->new();
	$self->{'_md5_'} = Digest::MD5->new;

	$self->{'prefix'}       = $ac->prefix();
	$self->{'install_path'} = $ac->install_path()."/".$self->{'app_name'};

	$self->{'conf_file'}    = $self->{'install_path'}."/".$ac->conf_file();
	$self->{'apache_uid'}   = $ac->apache_uid();
	$self->{'apache_gid'}   = $ac->apache_gid();

	unless (-e $self->{'conf_file'}) {
		die "Can't open configuration file: $self->{'conf_file'}\n";
	}

	$self->{'conf_data'} = { ParseConfig($self->{'conf_file'}) };

	bless $self, $class;
	return $self;
}

sub do_setup_checks {
	my $self = shift;

	my $install_path = $self->{'install_path'};
	my $prefix       = $self->{'prefix'};
	my $app_name     = $self->{'app_name'};

	$self->make_symlink("$install_path/code","$prefix/lib/perl/$app_name");

	$self->info("- Checking session directory:");
	$self->make_writeable_dirs($self->{'conf_data'}->{'session_dir'});
}

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
