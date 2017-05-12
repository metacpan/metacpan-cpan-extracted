use ExtUtils::MakeMaker;

my $me = "lib/ACH/Generator.pm";

WriteMakefile(
    'NAME'		=> 'ACH::Generator',
    'VERSION_FROM'	=> $me, 
    'PREREQ_PM'		=> { 
                             'ACH' => 0.01
                           },
    ($] < 5.005 ? () : (
       ABSTRACT_FROM => $me, 
       AUTHOR     => 'Christopher Kois <cpkois@cpan.org>') 
    ),
);
