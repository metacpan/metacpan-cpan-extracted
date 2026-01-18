requires 'perl', 'v5.24';

requires 'App::Greple', '10.02';
requires 'App::Greple::L', '1.01';
requires 'Command::Run', '0.9902';
requires 'Getopt::EX', '3.03';
requires 'Getopt::EX::Config';
requires 'Unicode::EastAsianWidth';

suggests 'App::ansifold', '1.34';
suggests 'App::ansicolumn', '1.50';
suggests 'App::cat::v', '1.05';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Data::Section::Simple';
    requires 'File::Spec';
    requires 'File::Slurper';
};

on 'develop' => sub {
    recommends 'App::Greple::xlate', '0.38';
    recommends 'App::Greple::subst::desumasu';
};

