requires 'Getopt::Long', '2.39';
requires 'LLEval';
requires 'Mouse';
requires 'Pod::Usage';
requires 'UnazuSan';
requires 'perl', '5.010001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::Exit';
    requires 'Test::More', '0.98';
};
