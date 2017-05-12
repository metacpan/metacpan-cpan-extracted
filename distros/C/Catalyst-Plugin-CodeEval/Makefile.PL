use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::CodeEval',
    VERSION_FROM      => 'lib/Catalyst/Plugin/CodeEval.pm', # finds $VERSION
    PREREQ_PM         => {'Catalyst' => '5.57',
			  'PadWalker' => '1.0'},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/CodeEval.pm', # retrieve abstract from module
       AUTHOR         => 'Shota Takayama <shot[atmark]bindstorm.jp>') : ()),
);
