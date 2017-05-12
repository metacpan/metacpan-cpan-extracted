
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Atheme',
                       'DISTNAME' => 'Atheme',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Pippijn van Steenhoven <pip88nl@gmail.com>, Stephan Jauernick <stephan@stejau.de>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Perl interface to Atheme\'s XML-RPC methods',
                       'EXE_FILES' => [],
                       'VERSION' => '0.0001',
                       'PREREQ_PM' => {
                                        'RPC::XML' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



