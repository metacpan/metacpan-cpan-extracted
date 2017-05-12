use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'AI::PSO',
    VERSION_FROM      => 'lib/AI/PSO.pm',
    PREREQ_PM         => { 'Math::Random' => 0, 'Callback' => 0},
    ($] >= 5.005 ?
      (AUTHOR         => 'W. Kyle Schlansker <kylesch@gmail.com>') : ()),
);
