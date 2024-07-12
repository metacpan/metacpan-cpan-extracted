requires 'perl', 'v5.36.0';

requires 'Class::Tiny',  '1.008';
requires 'Data::Gimei',  'v0.4.2';
requires 'Getopt::Long', '2.58';
requires 'Pod::Find',    '1.67';
requires 'Pod::Usage',   '2.03';
requires 'Pod::Text',    'v6.0.0';

on configure => sub {
    requires 'Module::Build::Tiny', '0.048';
};

on develop => sub {
    requires 'Minilla',           'v3.1.23';
    requires 'Perl::Tidy',        '20240511';
    requires 'Software::License', '0.104006';
    requires 'Version::Next',     '1.000';
    requires 'CPAN::Uploader',    '0.103018';
};

on 'test' => sub {
    requires 'Test2::Bundle::More', '0.000163';
    requires 'Unicode::GCString',   '2013.10';    # conflicts occur later than 2013.10 
    requires 'Capture::Tiny',       '0.48';
};
