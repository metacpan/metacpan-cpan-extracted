
    # ExtUtils::AutoInstall Bootstrap Code, version 7.
    BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.52;$p->VERSION||0>=$v
    or+eval"use $p $v;1"or+do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
    (!defined($e)||$e!~m/--(?:default|skip|testonly)/ and -t STDIN or
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
	-version	=> '0.40',	# required AutoInstall version
	                                # usually 0.40 is sufficient
	-config		=> {
	    make_args	=> '--hello',	# option(s) for CPAN::Config
	    force	=> 1,		# pseudo-option to force install
	    do_once	=> 1,		# skip previously failed modules
	},
	-core		=> [
		Convert::ASN1 => '',
		Net::LDAP => '',
		Apache2::Const => '',
		Apache2::Access => '',
		Apache2::Connection => '',
		Apache2::Log => '',
		Apache2::RequestRec => '',
		Apache2::RequestUtil => '',
	        mod_perl2 => '',
	], 		# core modules; may also be 'all'
    );

    WriteMakefile(
	AUTHOR          => 'Mark Wilcox (mjwilcox@wilcox.com) and Shannon Eric Peevey (shannonpeevey@gmail.com)',
	ABSTRACT        => 'Apache::AuthNetLDAP -- Perl module which authenticates users via LDAP using the Net::LDAP module.',
	NAME            => 'Apache::AuthNetLDAP',
	VERSION_FROM    => 'AuthNetLDAP.pm',
	DISTNAME        => 'Apache-AuthNetLDAP',
    );
