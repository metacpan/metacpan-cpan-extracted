
use ExtUtils::MakeMaker;


if ($^O =~ /win/i) {
  $ProToolkitIncludeDir = ' -Iprotk23-2002270/protoolkit/includes ';
  $ProToolkitDefines = ' -DPRO_MACHINE=29 ';
  $ExtraLibs = '../properl/properlexe.lib';
  # $ExtraLibs = '../properl/properldll.lib';
  $OtherLDFlags = '';
}
elsif ($^O =~ /solaris/i) {
  $ProToolkitIncludeDir = '-Iprotk23-2002180/protoolkit/includes ';
  $ProToolkitDefines = ' -DPRO_MACHINE=19 -DSOLARIS ';
  $ExtraLibs = '';
  $OtherLDFlags = '';
}


WriteMakefile(


    'NAME'		=> 'CAD::ProEngineer',


    # finds $VERSION
    #
    'VERSION_FROM'	=> 'ProEngineer.pm', 


    # e.g., Module::Name => 1.1
    #
    'PREREQ_PM'		=> {},


    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ProEngineer.pm', # retrieve abstract from module
       AUTHOR     => 'Marc Mettes <marcs_perl@yahoo.com>') : ()),


    # e.g., '-lm'
    #
    'LIBS' => [ $ExtraLibs . ' ' ],


    # e.g., '-DHAVE_SOMETHING'
    #
    'DEFINE'		=> $ProToolkitDefines . ' ',


    # Insert -I. if you add *.h files later: e.g., '-I/usr/include/other'
    #
    'INC'		=> $ProToolkitIncludeDir . ' ',


    # Un-comment this if you add C files to link with later:
    #
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too


    # Other stuff
    #
    'dynamic_lib' => {
        OTHERLDFLAGS => $OtherLDFlags,
    },


);

