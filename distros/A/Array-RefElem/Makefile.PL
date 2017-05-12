use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'Array::RefElem',
    VERSION_FROM => 'RefElem.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
