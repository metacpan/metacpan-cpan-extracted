require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
              'NAME'         => 'Dancer::Plugin::HTML::FormsDj',
              'VERSION_FROM' => 'lib/Dancer/Plugin/HTML/FormsDj.pm',
              'PREREQ_PM'    => {
                                  'HTML::FormsDj'       => 0.03,
                                },
              'AUTHOR'       => 'T. Linden <tlinden@cpan.org>',
              'clean'        => {
                                 FILES => 't/*.out *~ */*~ */*/*~ */*/*/*~'
                                },

);
