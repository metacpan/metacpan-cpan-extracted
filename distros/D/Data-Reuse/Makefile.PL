use 5.008001;
use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Data::Reuse",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'share constant values with Data::Alias',
 VERSION_FROM	=> 'lib/Data/Reuse.pm',
 LICENSE    => 'perl',

 PREREQ_PM	=> {qw(
		    Data::Alias	 1.16
                   )},
);
