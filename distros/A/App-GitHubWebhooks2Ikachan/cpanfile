requires 'Class::Accessor::Lite';
requires 'Encode';
requires 'Getopt::Long', '2.42';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'Log::Minimal';
requires 'Plack';
requires 'Pod::Usage';
requires 'String::IRC';
requires 'perl', '5.008001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'Hash::MultiValue';
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
