use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $we_are_upgrading=eval{
    require CGI::SecureState;
    return +($CGI::SecureState::VERSION<0.29) ? 1 : 0;
};

if ($we_are_upgrading) {
    print "*********************> WARNING! <*********************\n";
    print "* You are upgrading from a previous version of       *\n";
    print "* CGI::SecureState.  You MUST read the documentation *\n";
    print "* before installing this new version, as it will     *\n";
    print "* spit out nasty warnings if you use it on old       *\n";
    print "* scripts.  See                                      *\n";
    print "* http://search.cpan.org/search?dist=SecureState     *\n";
    print "* for more details.                                  *\n";
    print "******************************************************\n";

    print "Press <enter> only after you have read the documentation.\n";
    <STDIN>;
}


WriteMakefile(
    'NAME'		=> 'CGI::SecureState',
    'VERSION_FROM'	=> 'SecureState.pm',
    'PREREQ_PM'		=> {CGI => '2.0', Digest::SHA1 => '1.0', Crypt::Blowfish => '2.0',
			    Fcntl => '0.1', File::Spec => '0.1'},
    'DISTNAME'          => 'CGI-SecureState',
    'dist'              => { COMPRESS => 'gzip', SUFFIX => 'gz', },
);
