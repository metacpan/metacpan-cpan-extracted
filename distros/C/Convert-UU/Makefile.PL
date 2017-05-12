use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $mainfile = 'lib/Convert/UU.pm';
WriteMakefile(
              'NAME'	=> 'Convert::UU',
              'VERSION_FROM' => $mainfile,
              'EXE_FILES' => [qw(puudecode puuencode)],
              'dist' => {
                         DIST_DEFAULT => 'README all tardist',
                         COMPRESS => 'gzip -9f'
                        },
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
               (LICENSE      => "perl") : (),
              ),
);

sub MY::postamble {
  q{README: lib/Convert/UU.pm Makefile
	chmod +w $@
	pod2text lib/Convert/UU.pm > $@
}
}
