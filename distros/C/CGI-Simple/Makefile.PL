use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  #( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'CGI::Simple',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/CGI/Simple.pm',
  ABSTRACT_FROM => 'lib/CGI/Simple.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More' => 0,
    'IO::Scalar' => 0
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'CGI-Simple-*' },
);

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}
