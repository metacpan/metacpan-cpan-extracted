requires 'perl', 'v5.24';

requires 'App::Greple', '9.22';
requires 'App::Greple::L', '1.01';
requires 'App::sdif', '4.35';
requires 'Getopt::EX', 'v2.2.1';
requires 'Getopt::EX::Config';

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

