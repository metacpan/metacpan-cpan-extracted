    # ExtUtils::AutoInstall Bootstrap Code, version 7.
    BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.52;$p->VERSION||0>=$v
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

    # notify the user about mod_perl 2
    BEGIN { print q{
        **************** DEPENDENCY NOTICE *********************
        If you are planning to use mod_perl2 and Apache2, please, do not
        answer yes when prompted to install mod_perl.  You will need to
        download mod_perl2 manually from
        http://perl.apache.org/download/index.html
        *********************************************
      } 
    }    

    # optional pre-install handler; takes $module_name and $version
    # sub MY::preinstall  { return 1; }	# return false to skip install

    # optional post-install handler; takes $module_name, $version, $success
    # sub MY::postinstall { return; }	# the return value doesn't matter

    # the above handlers must be declared before the 'use' statement
    use ExtUtils::AutoInstall (
	-version	=> '0.40',	# required AutoInstall version
	                                # usually 0.40 is sufficient
	-config		=> {
	    make_args	=> '--hello',	# option(s) for CPAN::Config
	    force	=> 1,		# pseudo-option to force install
	    do_once	=> 1,		# skip previously failed modules
	},
	-core		=> [
	        mod_perl => '',
	        Apache::AuthenPasswd => '0.11',
	], 		# core modules; may also be 'all'
    );

    WriteMakefile(
	AUTHOR          => 'Demetrios E. Paneros (dep@media.mit.edu) and Shannon Eric Peevey (speeves@unt.edu)',
	ABSTRACT        => 'Apache::AuthzPasswd -- Perl module which authenticates users via /etc/groups file.',
	NAME            => 'Apache::AuthzPasswd',
	VERSION_FROM    => 'AuthzPasswd.pm',
	DISTNAME        => 'Apache-AuthzPasswd',
    );
