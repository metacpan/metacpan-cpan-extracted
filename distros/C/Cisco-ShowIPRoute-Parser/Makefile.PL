use ExtUtils::MakeMaker;


eval "use GraphViz;";
if($@)
{
	print "\a",<<'MSG';

===> Note <===
	The optional package GraphViz is missing. You want GraphViz it is
	great!.

	Check the CPAN and http://www.graphviz.org/ or
	http://www.research.att.com/sw/tools/graphviz/

	We can still run fine with out it. Just the ploting program will fail
	when you try to run it.

MSG

}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Cisco::ShowIPRoute::Parser',
    'VERSION_FROM'	=> 'Parser.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Parser.pm', # retrieve abstract from module
       AUTHOR     => 'Mark Pfeiffer and Rajiv Santiago') : ()),
	
);

