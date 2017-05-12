use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $opt = {
	'NAME'		=> 'Audio::Audiere::Audiere_perl',
	'DISTNAME'	=> 'Audio-Audiere',
	'VERSION_FROM'	=> 'lib/Audio/Audiere.pm',
	'PREREQ_PM'	=> {
			},
	($] >= 5.005 ?
		(ABSTRACT_FROM  => 'lib/Audio/Audiere.pm',
                AUTHOR         => 'Tels <http://bloodgate.com/>') : ()),
	'CC'		=> 'g++',
	'LD'		=> 'g++',
	'LIBS'		=> [ '-laudiere' ],
	'OPTIMIZE'	=> '-O2',
	'DEFINE'	=> '', # e.g., '-DHAVE_SOMETHING'
	'INC'		=> '',
	'XS'		=> { 'Audiere_perl.xs' => 'Audiere_perl.c'},
	'XSOPT'		=> '-C++', 

# not neccessary: (?)
#	'OBJECT'	=> 'Audiere_perl.o', 
 };

if ($^O =~ /win32/i)
  {
  $opt->{DEFINE} = ' -GX -TP ', 	# e.g., '-DHAVE_SOMETHING'
  $opt->{INC} = '-IC:\dev\audiere\audiere-1.9.3-win32\audiere-1.9.3-win32\include',
  delete $opt->{CC};
  delete $opt->{LD};
  }

foreach (keys %$opt)
  {
  push @o, $_, $opt->{$_};
  }

WriteMakefile( @o );
