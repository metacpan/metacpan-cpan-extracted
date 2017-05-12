use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Bio::ConnectDots',
    'VERSION_FROM'  => 'lib/Bio/ConnectDots/ConnectDots.pm', # finds $VERSION
    'PREREQ_PM'   => { Class::AutoClass => '0.09',
                       Test::XML::XPath => '',
                       Test::More => '',
                       DBD::Pg => '',
                       File::Path => '',
                       Carp => '',
                       Getopt::Long => '',
                       Text::Abbrev => '',
                       }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'David Burdick <dburdick@systemsbiology.org>, Nat Goodman <natg@shore.net>') : ()),
);
