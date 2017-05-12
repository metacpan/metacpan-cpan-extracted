use ExtUtils::MakeMaker;

eval "use XML::Parser; 1" 
  || warn "XML::Parser module not found.  This module is required to use Boulder::XML\n";

WriteMakefile(
    'NAME'	=> 'Boulder',
    'DISTNAME'  => 'Boulder',
    'VERSION_FROM'   => 'Stone.pm',
    'PMLIBDIRS' => ['Boulder','Stone'],
    'linkext'   => { LINKTYPE=>'' },	# no link needed
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
	            'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
);
