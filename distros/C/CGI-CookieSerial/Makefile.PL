use 5.006;
# ExtUtils::AutoInstall Bootstrap Code, version 5.
    BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.40;eval"use $p $v;1
    "or do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};(!defined($e)||$e
    !~m/--(?:default|skip|testonly)/and-t STDIN or eval"use Ext".
    "Utils::MakeMaker;WriteMakefile('PREREQ_PM'=>{'$p',$v});1"and
    exit)and print"==> $p $v required. Install it from CPAN? [Y".
    "/n] "and<STDIN>!~/^n/i and print"*** Installing $p\n"and do{
    eval{require CPANPLUS;CPANPLUS::install $p};eval"use $p $v;1"
    or eval{require CPAN;CPAN::install$p};eval"use $p $v;1"or die
    "*** Please install $p $v manually from cpan.org first.\n"}}}

    # optional pre-install handler; takes $module_name and $version
    # sub MY::preinstall  { return 1; } # return false to skip install

    # optional post-install handler; takes $module_name, $version, $success
    # sub MY::postinstall { return; }   # the return value doesn't matter

    # the above handlers must be declared before the 'use' statement
    use ExtUtils::AutoInstall (
	-version	=> '0.40',	# required AutoInstall version
	                                # usually 0.40 is sufficient
	-config		=> {
	    make_args	=> '--hello',	# option(s) for CPAN::Config
	    force	=> 1,		# pseudo-option to force install
	},
	'Required modules' => [
	    'CGI'		=> '2.89',
	    'CGI::Cookie' 	=> '1.21',
	    'Data::Serializer' 	=> '0.17',
	],
    );

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::CookieSerial',
    'VERSION_FROM'	=> 'CookieSerial.pm', # finds $VERSION
    'PREREQ_PM'		=> {
            'CGI'       => '2.89',
            'CGI::Cookie' => '1.21',
            'Data::Serializer' => '0.17',
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CookieSerial.pm', # retrieve abstract from module
       AUTHOR     => 'Duncan McGreggor <oubiwann@cpan.org>') : ()),
);
