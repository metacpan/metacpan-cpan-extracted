use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Apache::GzipChain',
	      'VERSION_FROM' => 'lib/Apache/GzipChain.pm', # finds $VERSION
              depend => { Makefile => '$(VERSION_FROM)' },
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
               (LICENSE      => "perl") : (),
              ),
	      'PREREQ_PM' => {
                              'Compress::Zlib' => 1.0,
			      'Apache::OutputChain' => 0.04,
                              strict => 0,
                              vars => 0,
                              FileHandle => 0,
                              'Apache::Constants' => 0,
                             },
	      dist => {
                       DIST_DEFAULT => 'README all tardist',
                       COMPRESS => 'gzip -9f'
		       # PREOP => 'co -l README && pod2text GzipChain.pm > README && ci -u README',
		      }
);

sub MY::postamble {
  q{
README: lib/Apache/GzipChain.pm Makefile
	chmod +w $@
	pod2text lib/Apache/GzipChain.pm > $@

}
}
