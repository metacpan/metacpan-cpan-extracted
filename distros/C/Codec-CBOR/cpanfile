on configure => sub {
    requires 'CPAN::Meta';
    requires 'Exporter',          '5.57';
    requires 'ExtUtils::Helpers', '0.028';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'File::Basename';
    requires 'File::Find';
    requires 'File::Path';
    requires 'File::Spec::Functions';
    requires 'Getopt::Long', '2.36';
    requires 'JSON::PP',     '2';
    requires 'Path::Tiny';
    requires 'perl', 'v5.40.0';
};
on build => sub {
    requires 'Module::Build::Tiny';
};
on test => sub {
    requires 'Test2::V0';
};
