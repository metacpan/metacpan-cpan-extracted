use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::SetWWWTheme',
    'VERSION_FROM' => 'SetWWWTheme.pm', # finds $VERSION
    'PREREQ_PM' => {'HTML::WWWTheme' => '1.06',
                    'Apache::Constants' => '0',},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    ('ABSTRACT_FROM' => 'SetWWWTheme.pm',
    'AUTHOR' => 'Chad Hogan <chogan@uvastro.phys.uvic.ca>') : ()),
);
