use ExtUtils::MakeMaker;

my $me = "lib/ACH/Parser.pm";

WriteMakefile(
    'NAME'		=> 'ACH::Parser',
    'VERSION_FROM'	=> $me, 
    'PREREQ_PM'		=> { 
                             'ACH' => 0.01
                           },
    ($] < 5.005 ? () : (
       ABSTRACT_FROM => $me, 
       AUTHOR     => 'Christopher Kois <cpkois@cpan.org>') 
    ),
);
