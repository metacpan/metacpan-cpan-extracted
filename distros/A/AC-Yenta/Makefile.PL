
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'AC::Yenta',
              VERSION_FROM    => 'lib/AC/Yenta.pm',
              ABSTRACT_FROM   => 'lib/AC/Yenta.pm',
              AUTHOR          => 'AdCopy <http://www.adcopy.com>',
              LICENSE         => 'perl',
              PREREQ_PM       => {
                  'POSIX'                       => 0,
                  'Sys::Hostname'	        => 0,
                  'JSON'		        => 0,
                  'Digest::SHA'		        => 0,
                  'Crypt::Rijndael'		=> 0,
                  'BerkeleyDB'		        => 0,
                  'Time::HiRes'			=> 0,
                  'Google::ProtocolBuffers'	=> 0,
		  'AC::DC'			=> 0,
              }
);
