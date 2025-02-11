requires 'perl', '5.024';

requires 'Hash::Util';
requires 'List::Util', '1.29';
requires 'Pod::Usage';
requires 'Getopt::Long';
requires 'Getopt::EX';
requires 'Getopt::EX::Hashed';
requires 'Text::ANSI::Fold', '2.29';
requires 'Text::ANSI::Tabs', '1.06';

on 'develop' => sub {
    recommends 'App::Greple::xlate';
    recommends 'App::Greple::subst::desumasu';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Data::Section::Simple';
    requires 'File::Spec';
    requires 'File::Slurper';
    requires 'App::sdif';
};

