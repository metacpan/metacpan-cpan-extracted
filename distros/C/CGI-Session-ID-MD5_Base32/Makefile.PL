use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Session::ID::MD5_Base32',
    'VERSION_FROM'	=> 'MD5_Base32.pm', # finds $VERSION
    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
		MIME::Base32  => 1.01,
		CGI::Session  => 0,
		Digest::MD5   => 0,
	}, 
    ($] >= 5.005 ? (
      # ABSTRACT_FROM => 'MD5_Base32.pm', 
      AUTHOR     => 'Daniel Peder <Daniel.Peder@infoset.com>',
    ) : ()),
);
sub MY::postamble { q{

docs : README

README: MD5_Base32.pm
	pod2text --loose MD5_Base32.pm > README

xdist:
	[ -f MANIFEST ] && rm -f MANIFEST ; make realclean docs manifest tardist; perl Makefile.PL

}; }
