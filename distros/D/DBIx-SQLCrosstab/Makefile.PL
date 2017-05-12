use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'DBIx::SQLCrosstab',
    'VERSION_FROM'	=> 'SQLCrosstab.pm', 
    'PREREQ_PM'		=>  {
                         DBI              => 1.20,
                         'Tree::DAG_Node' => 1.04
                        }, 
    ABSTRACT_FROM  => 'SQLCrosstab.pm', 
      AUTHOR       => 'Giuseppe Maxia <gmax@cpan.org>',
);
