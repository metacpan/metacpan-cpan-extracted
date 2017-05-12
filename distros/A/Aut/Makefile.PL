use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Aut',
    'VERSION_FROM'	=> 'Aut.pm', # finds $VERSION
    'PREREQ_PM'		=> { Crypt::RSA => 1.5, Crypt::CBC => 2.08, Crypt::Blowfish => 2.0, MIME::Base64 => 2.0, Digest::MD5 => 0, Term::ReadKey => 0, Locale::Framework => 0.06, Config::Frontend => 0.11, Config::Backend::INI => 0.11 },
    'ABSTRACT_FROM'     => 'Aut.pm', # retrieve abstract from module
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>'
);


