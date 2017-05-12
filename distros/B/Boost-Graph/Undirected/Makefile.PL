use 5.008;
use ExtUtils::MakeMaker;
$CC = 'g++ -O';
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Boost::Graph::Undirected',
    'VERSION_FROM'	=> 'Undirected.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Undirected.pm', # retrieve abstract from module
       AUTHOR     => 'David Burdick <dburdick@systemsbiology.org>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'CC'                => $CC,
    'LD'                => '$(CC)',
    'INC'		=> '-I. -I../include -I../include/boost', # MODIFY THIS! Point it to your Boost installation
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++',
    'TYPEMAPS'          => ['perlobject.map' ],
);
