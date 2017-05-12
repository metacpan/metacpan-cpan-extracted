use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AxKit::Provider::CGI',
    'VERSION_FROM'	=> 'CGI.pm',
    'PREREQ_PM'		=> {CGI::Utils => 0.03, XML::Simple => 2.08},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'CGI.pm',
       AUTHOR     => 'root <root@localdomain>') : ()),
);
