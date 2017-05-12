use ExtUtils::MakeMaker;


# Test for PDL::Options

eval "use PDL::Options";
if ($@) {
  die 'Error - the PDL::Options module must be installed before this module will run.\nThis module is available from CPAN';
}



# Create makefile

WriteMakefile(
    'NAME'      => 'Chart::GRACE',
    'VERSION_FROM' => 'GRACE.pm', # finds $VERSION
    'linkext'   => {LINKTYPE=>'' }, # no link needed
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                    'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'}
);

