package builder::MyBuilder;
use strict;
use warnings;
use parent qw/Module::Build/;
use File::ShareDir ':ALL';

sub ACTION_clean {
	my $self = shift;
	my $dir = eval { dist_dir('Cmd-Dwarf'); };
	if (defined $dir and -d $dir) {
		system("rm -rf $dir");
	}
	$self->SUPER::ACTION_clean;
}

sub ACTION_install {
	my $self = shift;
	my $dir = eval { dist_dir('Cmd-Dwarf'); };
	if (defined $dir and -d $dir) {
		system("rm -rf $dir");
	}
	$self->SUPER::ACTION_install;
}

1;
