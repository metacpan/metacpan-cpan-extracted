use ExtUtils::MakeMaker;
WriteMakefile(
  NAME         => 'Array::Average',
  VERSION_FROM => 'lib/Array/Average.pm',
  ABSTRACT_FROM=> 'lib/Array/Average.pm',
  AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
  PREREQ_PM    => {
                   'Test::Simple' => 0.44,
                   'Scalar::Util' => 0,
                   'Exporter'     => 0,
                   'vars'         => 0,
                  },
);
