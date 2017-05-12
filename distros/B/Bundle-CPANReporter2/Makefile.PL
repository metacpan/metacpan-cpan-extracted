use ExtUtils::MakeMaker;
use strict;

WriteMakefile
  (
   'NAME'	  => 'Bundle::CPANReporter2',
   'VERSION_FROM' => 'CPANReporter2.pm',
   'AUTHOR'       => 'rurban',
   'ABSTRACT'     => 'dependencies for CPAN::Reporter::Transport::Metabase',
   'LICENSE'      => 'Artistic 2',
   'SIGN'         => 1,
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  => {
      resources =>
      {
       repository  => 'https://github.com/rurban/Bundle-CPANReporter2',
       license     => 'http://dev.perl.org/licenses/',
      },
      release_status => 'stable',
     }) : ()),
  );






