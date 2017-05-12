#!/usr/bin/perl -w
use strict;
use Module::Build;

my $class = Module::Build->subclass(
	code => q{
		sub ACTION_deb {
			use strict;
			my $self = shift;
			$self->dispatch('distdir');
			my $distdir = $self->dist_name .'-'. $self->dist_version;
			my $lc_distdir = lc($distdir);

			# do_system echos
			$self->do_system("rm","-rf", $lc_distdir) or die $!;
			$self->do_system("mv", $distdir, $lc_distdir) or die $!;
			$self->do_system("cp","-r", "debian", $lc_distdir) or die $!;
			$self->add_to_cleanup($lc_distdir);

			$self->do_system("cd $lc_distdir  && debuild -us -uc") or die $!;
		}
	},
);

$class->new(
	module_name => 'Data::Rmap',
	license => 'perl',
	requires => {
		'Scalar::Util' => 0,
		'Test::Exception' => 0,
	},
	create_makefile_pl => 'traditional',
	meta_merge => {
		resources => {
			repository => 'https://github.com/bowman/Data-Rmap',
		},
	},
)->create_build_script;

