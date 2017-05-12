#!/usr/bin/perl
#
#       Perl Makefile for Attribute-Method-Typeable
#       $Id: Makefile.PL,v 1.6 2004/10/14 22:42:03 phaedrus Exp $
#
#	Invocation:
#		$ perl Makefile.PL                  # interactive behaviour
#		$ perl Makefile.PL --defaultdeps    # accept default value on prompts
#		$ perl Makefile.PL --checkdeps      # check only, no Makefile produced
#		$ perl Makefile.PL --skipdeps       # ignores all dependencies
#		$ perl Makefile.PL --testonly       # don't write installation targets
#
#	Then, to build:
#		$ make [all|test|install]           # install dependencies first
#		$ make checkdeps                    # same as the --checkdeps above
#		$ make installdeps                  # install dependencies only
#

# ExtUtils::AutoInstall Bootstrap Code, version 7.
BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.45;$p->VERSION||0>=$v
or+eval"use $p $v;1"or+do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
(!defined($e)||$e!~m/--(?:default|skip|testonly)/and-t STDIN or
eval"use ExtUtils::MakeMaker;WriteMakefile(PREREQ_PM=>{'$p',$v}
);1"and exit)and print"==> $p $v required. Install it from CP".
"AN? [Y/n] "and<STDIN>!~/^n/i and print"*** Installing $p\n"and
do{if (eval '$>' and lc(`sudo -V`) =~ /version/){system('sudo',
$^X,"-MCPANPLUS","-e","CPANPLUS::install $p");eval"use $p $v;1"
||system('sudo', $^X, "-MCPAN", "-e", "CPAN::install $p")}eval{
require CPANPLUS;CPANPLUS::install$p};eval"use $p $v;1"or eval{
require CPAN;CPAN::install$p};eval"use $p $v;1"||die"*** Please
manually install $p $v from cpan.org first...\n"}}}


# the above handlers must be declared before the 'use' statement
use ExtUtils::AutoInstall (
						   
						   # required AutoInstall version
						   -version        => '0.40',

						   # core modules; may also be 'all'
						   -core           => {
											   	Attribute::Handlers			=> 0.78,
												Data::Types					=> 0.05,
												Exception::Class	  		=> 1.16,
												Hook::WrapSub               => 0.03,
												Scalar::Util				=> 1.14,
												Test::SimpleUnit			=> 1.21,
						   },
	
						   'Use as a Mixin'        => {
												mixin					    => 0.04,
						   },
	);

WriteMakefile(
			  NAME				=> 'Attribute::Method::Typeable',
			  DISTNAME			=> 'Attribute-Method-Typeable',
			  VERSION_FROM		=> 'lib/Attribute/Method/Typeable.pm',
			  AUTHOR			=> 'Jeremiah Jordan <jjordan@perlreason.com>',
			  ABSTRACT			=> 'A mixin to allow Object Oriented description/verification of subroutine calls',

			  PM				=> {
									'lib/Attribute/Method/Typeable.pm' => '$(INST_LIBDIR)/Typeable.pm',
								   },
			  dist			=> {
								TARFLAGS		=> 'cvf',
								CI				=> "cvs commit",
								RCS_LABEL		=> 'cvs tag r$(VERSION_SYM)',
								SUFFIX			=> ".gz",
								DIST_CP         => 'ln',
								DIST_DEFAULT	=> 'all tardist',
								COMPRESS		=> "gzip",
							   },
			  clean			=> { FILES	=> "*.tar.bz2 *.tar.gz" },
			 );
