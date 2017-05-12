

use ExtUtils::MakeMaker 6.64;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Dancer::Plugin::Controller',
    VERSION_FROM => 'lib/Dancer/Plugin/Controller.pm', # finds \$VERSION
    AUTHOR       => 'Mikhail N Bogdanov (bogdanovmn@gmail.com)',
    ABSTRACT     => 'MVC-like',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Dancer' => 0,
                    },
    TEST_REQUIRES => {
                      'Dancer::Template::HtmlTemplate' => 0,
                     },
);
