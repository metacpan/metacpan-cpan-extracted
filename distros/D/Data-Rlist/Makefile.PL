#
# Makefile.PL
#
# To install this module type the following:
#
#	$ perl Makefile.PL
#	$ make
#	$ make test
#	$ make install
#
# See also perlnewmod, perlmodinstall, h2xs.
#
# MAKEMAKER'S MAKEFILE TARGETS
#
# distcheck: internal test wether this distributio is good, e.g.
#
#     $ perl Makefile.PL
#	  $ make distcheck
#
# disttest: run all tests without installing the distribution.
#
# dist: create archive to be uploaded to the PAUSE,
#     e.g. <Data-Rlist-1.43.tar.gz>.  The version number is read from
#     <./lib/Data/Rlist.pm>.
#
# realclean: delete everything that cannot be restored by the maintainer,
#     incl. the makefile generated.
#
# CPAN/PAUSE
#
# - https://pause.perl.org/
#
# - http://search.cpan.org/dist/Data-Rlist/
#
# - http://search.cpan.org/~aspindler/Data-Rlist-1.43/
#
##########
# $Writestamp: 2008-07-25 10:00:01 eh2sper$
# $Compile: make disttest && make dist$
# $Compile: perl Makefile.PL && make && make test$
# $Compile: make dist$
# $Clean: make realclean$

use 5.006;
use ExtUtils::MakeMaker;

eval { require 5.6.0 } or die <<'EOD';
############
### This module requires lvaluable subroutines, which are not available in
### versions of Perl earlier than 5.6.  Please upgrade!
############
EOD

# Problem with Cygwin: Unable to find a perl 5 (by these names:
# /usr/bin/perl.exe perl.exe perl5.exe perl5.8.8.exe miniperl.exe, in these
# dirs: /cygdrive/h/bin /usr/local/bin /usr/bin /bin /usr/X11R6/bin ...
#
# MakeMaker then renders an unusable Makefile! Why? $^O is "cygwin" and "which
# perl" suggests "/usr/bin/perl".

print "perl thinks the current OS is '$^O'\n";

#system('pod2html lib/Data/Rlist.pm >Rlist.pm.html');

WriteMakefile(
	NAME			=> 'Data::Rlist',
	VERSION_FROM	=> 'lib/Data/Rlist.pm', # finds $VERSION
	PREREQ_PM		=> {					# e.g., Module::Name => 1.1
		# These modules are required for testing only (i.e., by the t/*.t
		# scripts).  Rlist.pm does not use them.  However, I do not know which
		# version numbers shall be defined here. I could use the version on my
		# machines, but this seems to be now statement.
		'Benchmark' => '0',					# round.t
		'B::Deparse' => '0',				# deparse.t
		'MIME::Base64' => '0'				# binary.t, nanoscript.t
    },

    ($] >= 5.005 ?				# add these new keywords supported since 5.005
	 (ABSTRACT_FROM => 'lib/Data/Rlist.pm', # retrieve abstract from module
	  AUTHOR		=> 'Andreas Spindler <rlist@visualco.de>') : ()),

	clean => { FILES => ['*.tmp', 't/*.tmp'] },
#	dist => { TARFLAGS => 'cvfF', COMPRESS => 'gzip -9f', SUFFIX => '.gz' }
			 );
