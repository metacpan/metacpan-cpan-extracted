use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CopyTree::VendorProof::LocalFileOp',
    VERSION_FROM      => 'lib/CopyTree/VendorProof/LocalFileOp.pm', # finds $VERSION
    PREREQ_PM         => {CopyTree::VendorProof => 0.0011, MIME::Base64=>0, File::Basename=> 0, Data::Dumper=> 0, Carp=>0}, # e.g., Module::Name => 1.1
    #PREREQ_PM         => {CopyTree::VendorProof => 0.0011, MIME::Base64=>3.01, File::Basename=> 2.72, Data::Dumper=> 2.121, Carp=>1.02}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CopyTree/VendorProof/LocalFileOp.pm', # retrieve abstract from module
       AUTHOR         => 'dbmolester de gmail.com') : ()),
);
