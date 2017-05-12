use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'CGI::Session::ID::MD5_Base64',
    'VERSION_FROM'	=> 'MD5_Base64.pm', # finds $VERSION
    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
		MIME::Base64  => 0,
		CGI::Session  => 0,
		Digest::MD5   => 0,
	}, 
    ($] >= 5.005 ? (
      # ABSTRACT_FROM => 'MD5_Base64.pm', 
      AUTHOR     => 'Daniel Peder <Daniel.Peder@infoset.com>',
    ) : ()),
);
sub MY::postamble { q{

docs : README

README: MD5_Base64.pm
	pod2text --loose MD5_Base64.pm > README

xdist:
	[ -f MANIFEST ] && rm -f MANIFEST ; make realclean docs manifest tardist; perl Makefile.PL

}; }
