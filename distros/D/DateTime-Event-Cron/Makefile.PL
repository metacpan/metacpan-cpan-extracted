use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'DateTime::Event::Cron',
  'VERSION_FROM' => 'lib/DateTime/Event/Cron.pm',
  'PREREQ_PM'    => {
                      DateTime      => 0.21,
                      DateTime::Set => 0.1406,
                      Set::Crontab  => 0,
                    },
  'ABSTRACT_FROM' => 'lib/DateTime/Event/Cron.pm',
  'AUTHOR'        => 'Matthew P. Sisk  <sisk@mojotoad.com>',
);
