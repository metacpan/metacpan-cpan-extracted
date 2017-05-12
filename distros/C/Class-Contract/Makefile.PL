use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Class::Contract',
    'VERSION_FROM' => 'lib/Class/Contract.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 5.43
      ? ()
      : ('AUTHOR'        => 'Garrett Goebel (ggoebel@cpan.org)',
	       'ABSTRACT_FROM' => 'lib/Class/Contract.pm')
    )
);

warn <<'EOT';

    Remember to actually *read* the README file!
    o  Use  'make' to build the software.
    o  Then 'make test' to execute self tests.
    o  Then 'make install' to install

EOT

warn <<'EOT'  if $^O eq 'MSWin32';
    Notes to Windows users:
    o  You may need to use the correct make command. That may be nmake
       or dmake depending on your C compiler. 
    o  If you are using a Win32 ActiveState build then it is recommended
       that you use the ppm utility to fetch and install Class::Contract
       (of course, I have yet to create one... but maybe you will?)
EOT

exit 0;

