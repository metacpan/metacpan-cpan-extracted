use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # the contents of the Makefile that is written.
  WriteMakefile(
      'NAME' => 'Crypt::PGPSimple',
      'VERSION_FROM' => 'PGPSimple.pm', # finds $VERSION
      ($] ge '5.005') ? (
          'AUTHOR' => 'Jason Hinkle (jake67890@hotmail.com)',
          'ABSTRACT' => 'Object-oriented interface to PGP',
      ) : (),
  );
