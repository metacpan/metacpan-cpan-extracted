use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME	            => "B::Debugger",
   VERSION_FROM     => "lib/Od.pm",
   PREREQ_PM 	    => {
			'Devel::Hook' => 0,
			'B::Concise' => '0.66',
			'B::Flags'   => '0.02',
			'B::Utils'   => '0.05',
			'B' 	     => '1.09',
   },
   depend           => { 'README'   => 'lib/B/Debugger.pm' },
   SIGN  => 1,
   ($ExtUtils::MakeMaker::VERSION gt '6.30'?
    ('LICENSE'                => 'perl', ) : ()),
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'   => {
      resources =>
      {
	license     => 'http://dev.perl.org/licenses/',
	repository  => 'http://github.com/rurban/B-Debugger',
      },
     }
    ) : ()),
   ($] >= 5.005 ?
    ('AUTHOR' => 'Reini Urban <rurban@cpan.org>',
     'ABSTRACT_FROM' => 'lib/B/Debugger.pm') : ()),
  );

#sub MY::depend { "\nDebugger.c : Debugger.xs Makefile\n"; }
#sub MY::depend { "
#README : lib/B/Debugger.pm
#	pod2text lib/B/Debugger.pm > README
#       # add 2 lines for Od to README
#"; }
