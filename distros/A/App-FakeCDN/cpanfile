requires 'Cache::Memory::Simple';
requires 'Getopt::Long';
requires 'Mouse';
requires 'Mouse::Util::TypeConstraints';
requires 'Path::Tiny';
requires 'Plack::Loader';
requires 'Plack::MIME';
requires 'Plack::Runner';
requires 'Pod::Usage';
requires 'perl', '5.010001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More';
};
