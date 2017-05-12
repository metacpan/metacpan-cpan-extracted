use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Algorithm::StringHash::FromCSharp35::XS',
    VERSION_FROM      => 'lib/Algorithm/StringHash/FromCSharp35/XS.pm', # finds $VERSION
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/StringHash/FromCSharp35/XS.pm', 
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
