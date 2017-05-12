use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Convert::BulkDecoder',
    'VERSION_FROM'	=> 'BulkDecoder.pm', # finds $VERSION
    'PREREQ_PM'		=> { MIME::Parser => 0,
			     Digest::MD5 => 0,
			     Test::More => 0,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'BulkDecoder.pm', # retrieve abstract from module
       AUTHOR     => 'Johan Vromans <jvromans@squirrel.nl>') : ()),
);
