requires 'perl', '5.022001';

requires 'Class::Tiny',  '1.008';
requires 'Data::Gimei',  '>=v0.4.0, < v0.5.0';
requires 'Getopt::Long', '2.54';
requires 'Pod::Find',    '1.66';
requires 'Pod::Usage',   '2.03';

on configure => sub {
    requires 'Module::Build::Tiny', '0.046';
};

on develop => sub {
    requires 'Perl::Tidy', '20230701';
};

on 'test' => sub {
    requires 'Test::More', '1.302195';
    requires 'Capture::Tiny', '0.48';
};
