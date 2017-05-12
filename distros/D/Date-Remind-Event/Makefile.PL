use inc::Module::Install;
license 'GPL';
name 'Date-Remind-Event';
all_from 'lib/Date/Remind/Event.pm';

build_requires 'Test::More' => 0;

requires 'DateTime'           => 0;
requires 'DateTime::Duration' => 0;

#install_script  'bin/rnp';
#install_script  'bin/rnpt';

resources
  bugtracker =>
  'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Remind-Event',
  repository => 'git://github.com/mlawren/date-remind-event.git';

WriteAll;

