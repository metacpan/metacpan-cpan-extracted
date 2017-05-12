use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'CGI::WebGzip',
    'VERSION_FROM'  => 'WebGzip.pm', # finds $VERSION
    'PREREQ_PM'   => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'CGI::WebGzip - Perl extension for GZipping script output',
       AUTHOR     => 'Dmitry Koterov <koterov at cpan dot org>') : ()),
);
