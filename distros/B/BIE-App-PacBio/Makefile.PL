use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BIE::App::PacBio',
    VERSION_FROM      => 'lib/BIE/App/PacBio.pm', # finds $VERSION
	      PREREQ_PM         => {
				    'BIE::Data::HDF5::File' => 0.01,
				    'namespace::autoclean' => 0.13,
				    'Moose' => 2.0,
				    'PDL' => '2.4.10',
				    'PDL::Graphics::PLplot' => 0.61,
				   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/BIE/App/PacBio.pm', # retrieve abstract from module
       AUTHOR         => 'Xin Zheng <zhengxin@mail.nih.gov>') : ()),
);

system 'mkdir -p blib/bin';
system 'cp script/pacbioBas.pl blib/bin';
