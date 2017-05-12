use ExtUtils::MakeMaker;


WriteMakefile(
  NAME => 'Crypt::Simple::SMIME',
  VERSION_FROM => 'lib/Crypt/Simple/SMIME.pm',
  PREREQ_PM => {
				'File::Temp'	=> 0,
               },
);

 