package Local::ModuleBuild;

use strict;
use warnings;
BEGIN { require Module::Build; push our @ISA, 'Module::Build' }

unless(__PACKAGE__->can("cbuilder")) {
	*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
}
unless(__PACKAGE__->can("have_c_compiler")) {
	*have_c_compiler = sub {
		my $cb = eval { $_[0]->cbuilder };
		return $cb && $cb->have_compiler;
	};
}
unless(eval { Module::Build->VERSION('0.33'); 1 }) {
	# Older versions of Module::Build have a bug where if the
	# cbuilder object is used at Build.PL time (which it will
	# be for this distribution due to the logic in
	# ->find_xs_files) then that object can be dumped to the
	# build_params file, and then at Build time it will
	# attempt to use the dumped blessed object without loading
	# the ExtUtils::CBuilder class that is needed to make it
	# work.
	*write_config = sub {
		delete $_[0]->{properties}->{_cbuilder};
		return $_[0]->SUPER::write_config;
	};
}
sub find_xs_files {
	my($self) = @_;
	return {} unless $self->have_c_compiler;
	return $self->SUPER::find_xs_files;
}

1;
