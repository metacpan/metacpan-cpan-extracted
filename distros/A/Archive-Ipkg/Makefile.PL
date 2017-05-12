use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		      => 'Archive::Ipkg',
    'VERSION_FROM'	=> 'Ipkg.pm', # finds $VERSION
    'PREREQ_PM'		  => {Archive::Tar   => 0.072,
                        Compress::Zlib => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Ipkg.pm', # retrieve abstract from module
       AUTHOR     => 'Christian Renz <crenz@web42.com>',
       LICENSE    => 'perl') : ()),
);
