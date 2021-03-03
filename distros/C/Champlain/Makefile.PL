use strict;
use warnings;

use ExtUtils::MakeMaker;

use Cwd;
use File::Spec;

use Glib::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

my $DEPENDS;
my @XS_FILES = ();

exit main();

sub main {
	
	# Create the build folder used by the code generation utilities
	mkdir 'build', 0777;
	
	# The version of libchamplain (and friends) for which this module can built against
	my $champlain_version = '0.5';
	
	# Find libchamplain
	my @typemaps = ();
	my @deps = ('Glib');
	my %pkgconfig;
	my %requires;

# 	eval {
# 		%pkgconfig = ExtUtils::PkgConfig->find("champlain-$champlain_version");
# 		push @XS_FILES, Glib::MakeHelper->read_source_list_file('xs-champlain');
# 		push @typemaps, 'maps';
# 		push @deps, 'Clutter';
# 		$requires{Clutter} = '1.000';
# 	};
# 	if (my $error = $@) {
# 		warn "FAIL: ", $error;
# 		return;
# 	}
# 	
# 	# If libchamplain was compiled with memphis support
# 	eval {
# 		# We build the bindigns with memphis support if we find the .pc file and
# 		# load the perl module successfully.
# 		my %conf = ExtUtils::PkgConfig->find("champlain-memphis-$champlain_version");
# 		my $version = '0.01';
# 		eval "use Memphis $version; 1;" or die "$@";
# 
# 		$requires{Memphis} = $version;
# 		$pkgconfig{cflags} .= $conf{cflags} . ' -DCHAMPLAINPERL_MEMPHIS';
# 		$pkgconfig{libs} .= $conf{libs};
# 
# 		push @XS_FILES, Glib::MakeHelper->read_source_list_file('xs-memphis');
# 		push @typemaps, 'maps-memphis';
# 		push @deps, 'Memphis';
# 	};
# 	if (my $error = $@) {
# 		warn "Ignoring the Memphis bindings ($error)";
# 	}
# 
# 	foreach my $module (keys %requires) {
# 		my $version = $requires{$module};
# 		eval "use $module '$version'; 1;" or die "Can't load $module $version\n";
# 	}
# 	
	$DEPENDS = ExtUtils::Depends->new('Champlain', @deps);
	$DEPENDS->add_pm(
		File::Spec->catfile('lib', 'Champlain.pm'),
		File::Spec->catfile('$(INST_LIBDIR)', 'Champlain.pm'),
	);

	# Code generation
	Glib::CodeGen->parse_maps('champlain', input => [ @typemaps ]);
	Glib::CodeGen->write_boot(
		xs_files => [ @XS_FILES ],
		ignore   => qr/^Champlain$/,
	);
	
	
	$DEPENDS->set_inc($pkgconfig{cflags} . ' -I./build');
	$DEPENDS->set_libs($pkgconfig{libs});
	$DEPENDS->add_xs(@XS_FILES);
	$DEPENDS->add_typemaps(
		File::Spec->catfile(cwd(), 'build', 'champlain.typemap')
	);
	$DEPENDS->install(
		File::Spec->catfile('build', 'champlain-autogen.h'),
		'champlain-perl.h',
	);
	$DEPENDS->save_config(File::Spec->catfile('build', 'IFiles.pm'));
	

	# Create the Makefile
	WriteMakefile(
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'Champlain',
		VERSION_FROM  => File::Spec->catfile('lib', 'Champlain.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Champlain.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			%requires,
		},
		PREREQ_FATAL  => 1, # Clutter is mandatory otherwise the Makefile can't be created
		
		XSPROTOARG    => '-noprototypes ',
		MAN3PODS      => {
			Glib::MakeHelper->do_pod_files(@XS_FILES),
		},

		META_MERGE => {
			repository   => 'https://gitlab.gnome.org/GNOME/perl-champlain/-/tree/master',
			x_deprecated => 1,
		},

		$DEPENDS->get_makefile_vars(),
		
		# Remove the build folder when doing "make clean"
		clean => {
			FILES => 'build',
		},
	);

print <<__EON__;
NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

* Perl URL: https://gitlab.gnome.org/GNOME/perl-champlain
* Upstream URL: https://gitlab.gnome.org/GNOME/libchamplain

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

	return 0;
}


sub MY::postamble {
	
	my $postamble = Glib::MakeHelper->postamble_clean();
	$postamble .= Glib::MakeHelper->postamble_docs_full(
		DEPENDS   => $DEPENDS,
		XS_FILES  => [ @XS_FILES ],
		COPYRIGHT => 'Copyright (C) 2009-2010 by Emmanuel Rodriguez'
	);

	return $postamble;
}
