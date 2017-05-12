use inc::Module::Install;

my $module = 'Catalyst::Plugin::LeakTracker';

my $dist   = $module;
$dist =~ s/::/-/g;
name($dist);

my @path = split '::', $module;
all_from('lib/'. (join '/',@path). '.pm');

requires 'Catalyst::Runtime' => '5.7010';
requires 'Task::Weaken' => '1.02';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
build_requires 'ok';

requires 'Catalyst::Plugin::C3';

requires 'Class::Data::Inheritable';

requires 'Devel::Events';
requires 'Devel::Events::Objects';

WriteAll();
