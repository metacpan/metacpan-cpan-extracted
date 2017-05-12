use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Crypt::Simple',
    'VERSION_FROM'	=> 'Simple.pm',
    'PREREQ_PM'		=> {
                         'Crypt::Blowfish' => 2.06,
                         'Compress::Zlib' => 1.11,
                         'MIME::Base64' => 2.11,
                         'Digest::MD5' => 2.13,
                         'FreezeThaw' => 0.41,
                       },
);
