requires 'perl', 'v5.18.2';

requires 'App::Greple', '9.1506';
requires 'App::sdif', '4.35';

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

