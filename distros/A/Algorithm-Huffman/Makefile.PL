use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Algorithm::Huffman',
    'VERSION_FROM'	=> 'Huffman.pm', # finds $VERSION
    'PREREQ_PM'		=> {
         Heap             => 0,
         Heap::Fibonacci  => 0,
         Heap::Elem       => 0,
         Tree::DAG_Node   => 0,
         List::Util       => 0,
         Carp             => 0,

         # Modules for the test script
         Test::More       => 0,
         Test::ManyParams => 0.04,
         Test::Exception  => 0,
         Data::Dumper     => 0,
         String::Random   => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
