#
# $Id: Makefile.PL 9 2015-01-13 18:13:54Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Bundle::Net::Frame',
   VERSION_FROM => 'lib/Bundle/Net/Frame.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Bundle/Net/Frame.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
);
