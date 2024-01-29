requires 'perl', 'v5.36.0';

requires 'Class::Tiny',  '1.008';
requires 'Data::Gimei',  '>=v0.4.0, <v0.5.0';
requires 'Getopt::Long', '2.54';
requires 'Pod::Find',    '1.66';
requires 'Pod::Usage',   '2.03';
requires 'Pod::Text',    '<5.00';

on configure => sub {
    requires 'Module::Build::Tiny', '0.046';
};

on develop => sub {
    requires 'Minilla';
    requires 'Perl::Tidy', '20230701';
    requires 'Software::License', '0.104005';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};

on 'test' => sub {
    requires 'Test::More', '1.302195';
    requires 'Capture::Tiny', '0.48';
};
