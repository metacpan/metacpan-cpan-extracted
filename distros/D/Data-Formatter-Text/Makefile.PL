use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Formatter::Text',
    VERSION_FROM      => 'lib/Data/Formatter/Text.pm', # finds $VERSION
    PREREQ_PM         => {
		"Attribute::Abstract" => 0,
		"Scalar::Util" => 0,
		"List::Util" => 0,
		"List::MoreUtils" => 0,
		"Roman" => 0,	
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Formatter/Text.pm', # retrieve abstract from module
       AUTHOR         => 'Zachary Blair <zack_blair@hotmail.com>') : ()),
);
