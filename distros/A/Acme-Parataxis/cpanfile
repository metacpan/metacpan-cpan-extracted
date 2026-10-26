requires 'Affix', 'v1.2.6';
requires 'File::Basename';
requires 'File::Spec';
on configure => sub {
    requires 'Affix', 'v1.2.6';
    requires 'Affix::Build';
    requires 'CPAN::Meta',        '2.150012';
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
    requires 'Test2::V1';
    requires 'perl', 'v5.40.0';
};
on build => sub {
    requires 'Test2::V1';
};
on test => sub {
    requires 'Test2::V1';
    recommends 'IO::Socket::IP',  '0.32';
    recommends 'IO::Socket::SSL', '1.968';
    recommends 'Net::SSLeay',     '1.49';
};
