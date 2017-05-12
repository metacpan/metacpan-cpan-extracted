
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'AC::DC',
              VERSION_FROM    => 'lib/AC/DC.pm',
              ABSTRACT_FROM   => 'lib/AC/DC.pm',
              AUTHOR          => 'AdCopy <http://www.adcopy.com>',
              LICENSE	      => 'perl',
              PREREQ_PM       => {
                  'Sys::Syslog'		=> 0,
                  'Sys::Hostname'	=> 0,
                  'POSIX'		=> 0,
                  'Time::Local'		=> 0,
                  'MIME::Base64'	=> 0,
                  'Unicode::Normalize'	=> 0,
                  'Digest::SHA1'	=> 0,
                  'Time::HiRes'		=> 0,
              },
);
