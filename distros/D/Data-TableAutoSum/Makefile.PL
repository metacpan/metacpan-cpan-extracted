use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::TableAutoSum',
    'VERSION_FROM'	=> 'TableAutoSum.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       Params::Validate   => 0,
       Regexp::Common     => 0,
       Set::Scalar        => 0,
       List::Util         => 0,
       Tie::File          => 0,
       Tie::CSV_File      => 0.06,
       Data::Compare      => 0,
       
       Math::Random       => 0,     # for the tests
       Set::CrossProduct  => 0,
       Data::Dumper       => 0,

       Test::More         => 0,    
       Test::Exception    => 0,
       Test::Builder      => 0.13,  # need maybe_regexp
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TableAutoSum.pm', # retrieve abstract from module
       AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
