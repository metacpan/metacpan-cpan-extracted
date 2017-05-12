require 5.000_000;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Class::ExtraAttributes",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'extra attributes for a class',
 VERSION_FROM	=> 'lib/Class/ExtraAttributes.pm',
 PREREQ_PM	=> { qw(
                    OOB    0.08
                   ) },
);
