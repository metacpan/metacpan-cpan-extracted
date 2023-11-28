requires 'perl', '5.014';

requires 'App::Greple', '9.07';
requires 'App::sdif', '4.25.1';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Data::Section::Simple';
    requires 'File::Spec';
    requires 'File::Slurper';
};

on 'develop' => sub {
    recommends 'App::Greple::xlate';
    recommends 'App::Greple::subst::desumasu';
};

