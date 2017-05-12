use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::GD::Thumbnail',
    'VERSION_FROM'	=> 'Thumbnail.pm', # finds $VERSION
    'PREREQ_PM'		=> {Apache::File=>1.01,GD=>1.38,Image::GD::Thumbnail=>0.02}, # e.g., Module::Name => 1.1
);
