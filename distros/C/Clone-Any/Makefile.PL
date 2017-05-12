use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Clone::Any',
    'VERSION_FROM' => 'Any.pm', 
    'PREREQ_PM'		=> {
      Devel::UseAnyFunc => 1,
    }, 
    ($] >= 5.005 ? (
      AUTHOR     => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);

