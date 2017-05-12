use strict;
use ExtUtils::MakeMaker;
use 5.006;


WriteMakefile(
    NAME         => 'Bio::IlluminaSAV',
    VERSION_FROM => 'Bio/IlluminaSAV.pm',
    AUTHOR       => 'Erik Aronesty <earonesty@cpan.org>',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0,
                     'Test::Deep' => 0,
                     'XML::LibXML::Reader' => 0,
                    },
    PM           => {'Bio/IlluminaSAV.pm'=>'$(INST_LIBDIR)/IlluminaSAV.pm'},
    dist	 => {
		     PREOP=>'pod2text Bio/IlluminaSAV.pm > README'
		    },
);
