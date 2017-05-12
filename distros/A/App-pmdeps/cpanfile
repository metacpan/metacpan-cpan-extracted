requires 'perl',             '5.008001';
requires 'Furl',             '2.16';
requires 'Getopt::Long',     '2.39';
requires 'JSON',             '2.59';
requires 'Module::CoreList', '2.91';
requires 'Term::ANSIColor',  '4.02';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on 'test' => sub {
    requires 'Capture::Tiny',             '0.22';
    requires 'Test::MockObject::Extends', '1.20120301';
    requires 'Test::More',                '0.98';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
