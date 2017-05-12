
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'AC::MrGamoo',
              VERSION_FROM    => 'lib/AC/MrGamoo.pm',
              ABSTRACT_FROM   => 'lib/AC/MrGamoo.pm',
              AUTHOR          => 'AdCopy <http://www.adcopy.com>',
              LICENSE         => 'perl',
              PREREQ_PM       => {
                  'POSIX'                       => 0,
                  'Sys::Hostname'	        => 0,
                  'JSON'		        => 0,
                  'Digest::SHA1'	        => 0,
                  'Time::HiRes'			=> 0,
                  'Google::ProtocolBuffers'	=> 0,
		  'AC::DC'			=> 0,
              }
);
