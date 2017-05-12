use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'AxKit::Plugin::DisableXSLTParams',
    'VERSION_FROM'	=> 'DisableXSLTParams.pm',
    'AUTHOR'        => 'Robin Berjon',
    'ABSTRACT'      => 'A plugin that disables params for XSLT',
    'PREREQ_PM'		=> {
                        AxKit   => '1.5',
                       },
);
