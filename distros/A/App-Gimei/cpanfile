requires 'perl', 'v5.40.0';

requires 'Class::Tiny',  '1.008';
requires 'Data::Gimei',  'v0.4.3';
requires 'Getopt::Long', '2.58';
requires 'Pod::Find',    '1.67';
requires 'Pod::Usage',   '2.05';
requires 'Pod::Text',    'v6.0.2';

on configure => sub {
    requires 'Module::Build::Tiny', '0.052';
};

on develop => sub {
    requires 'CPAN::Uploader',    '0.103018';
    requires 'Minilla',           'v3.1.29';
    requires 'Perl::Tidy',        '20260109';
    requires 'Software::License', '0.104007';
    requires 'Version::Next',     '1.000';
};

on 'test' => sub {
    requires 'Capture::Tiny',       '0.50';
    requires 'Test2::Bundle::More', '1.302219';
    requires 'Unicode::GCString',   '2013.10';    # conflicts occur later than 2013.10 
    requires 'Capture::Tiny',       '0.50';
};
