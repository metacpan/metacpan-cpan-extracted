use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> 'CGI::XML',
    VERSION_FROM => 'XML.pm',
    PREREQ_PM => { XML::Parser => '2.16' }
);
