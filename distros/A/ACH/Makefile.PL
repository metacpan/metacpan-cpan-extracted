use ExtUtils::MakeMaker;

my $me = "lib/ACH.pm";

WriteMakefile(
    'NAME'		=> 'ACH',
    'VERSION_FROM'	=> $me, 

    ($] < 5.005 ? () : (
       ABSTRACT_FROM => $me, 
       AUTHOR     => 'Christopher Kois <cpkois@cpan.org>') 
    ),
);
