use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Apache::WebDAV',
    'VERSION_FROM' => 'lib/Apache/WebDAV.pm', # finds $VERSION
    'PREREQ_PM'    => {
        'Apache'                             => 0,
        'Apache::Constants'                  => 0,
        'Apache::Util'                       => 0,
        'Encode'                             => 0,
        'File::Spec'                         => 0,
        'File::Find::Rule::Filesys::Virtual' => 0,
        'URI'                                => 0,
        'URI::Escape'                        => 0,
        'XML::Simple'                        => 0,
        'XML::LibXML'                        => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Apache/WebDAV.pm', # retrieve abstract from module
       AUTHOR     => 'Brian Lozier, Geospiza, Inc. <lozier@geospiza.com>') : ()),
);
