use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Alias',
    'VERSION_FROM'	=> 'Alias.pm',
    'linkext'   => {LINKTYPE => 'dynamic'},
    'dist'      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
);
