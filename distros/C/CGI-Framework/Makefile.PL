use ExtUtils::MakeMaker;

# $Header: /cvsroot/CGI::Framework/Makefile.PL,v 1.3 2003/04/28 22:10:28 mina Exp $

WriteMakefile(
    NAME         => 'CGI::Framework',
    VERSION_FROM => 'lib/CGI/Framework.pm', # finds $VERSION
    AUTHOR       => 'Mina Naguib (mnaguib@cpan.org)',
    ABSTRACT     => 'A simple to use web CGI framework',
    PREREQ_PM    => {
      'HTML::Template' => 0,
      'CGI::Session'   => 0,
		'CGI'            => 0,
		'CGI::Carp'      => 0,
    },
);
