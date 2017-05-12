
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Business::IS::PIN',
                       'DISTNAME' => 'Business-IS-PIN',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Validate and process Icelandic PIN numbers (Icelandic: kennitE<ouml>lur)',
                       'EXE_FILES' => [],
                       'VERSION' => '0.06',
                       'PREREQ_PM' => {
                                        'List::Util' => '0',
                                        'Test::More' => '0',
                                        'overload' => '0',
                                        'File::Spec::Functions' => '0',
                                        'Exporter' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



