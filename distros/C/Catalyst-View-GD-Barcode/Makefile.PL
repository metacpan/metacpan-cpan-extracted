use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::View::GD::Barcode',
    VERSION_FROM      => 'lib/Catalyst/View/GD/Barcode.pm', # finds $VERSION
    PREREQ_PM         => {GD::Barcode => 1.15, Catalyst => 5.57}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/View/GD/Barcode.pm', # retrieve abstract from module
       AUTHOR         => 'Toshimitu Yanagisawa <yanagisawa@shanon.co.jp>') : ()),
);
