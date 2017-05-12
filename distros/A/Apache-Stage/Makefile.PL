use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'Apache::Stage',
	      'VERSION_FROM' => 'Stage.pm', # finds $VERSION
              depend => { Makefile => '$(VERSION_FROM)' },
	      dist => {
                       DIST_DEFAULT => 'README all tardist',
		       SUFFIX => 'gz',
		       COMPRESS => 'gzip -9',
		      }
);

sub MY::postamble {
  q{
README: Stage.pm Makefile
	chmod +w $@
	pod2text Stage.pm > $@

}
}
