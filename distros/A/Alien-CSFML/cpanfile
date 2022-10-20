requires 'perl', '5.010000';
on configure => sub {
    requires 'Archive::Extract';
    requires 'CPAN::Meta', '0';
    requires 'Devel::CheckBin';
    requires 'Exporter', '5.57';
    requires 'ExtUtils::CBuilder';
    requires 'ExtUtils::Config',  '0.003';
    requires 'ExtUtils::Helpers', '0.020';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'ExtUtils::ParseXS';
    requires 'File::Basename';
    requires 'File::Copy';
    requires 'File::Copy::Recursive';
    requires 'File::Find';
    requires 'File::Path';
    requires 'File::pushd';
    requires 'File::ShareDir';
    requires 'File::Slurp';
    requires 'File::Spec::Functions';
    requires 'Getopt::Long';
    requires 'HTTP::Tiny';
    requires 'JSON::Tiny';
    requires 'Pod::Man';
    requires 'TAP::Harness';
};
on build => sub {
    requires 'Archive::Extract';
    requires 'File::Copy';
    requires 'File::Copy::Recursive';
    requires 'File::pushd';
    requires 'File::ShareDir';
    requires 'File::Slurp';
    requires 'File::Spec::Functions';
    requires 'HTTP::Tiny';
    requires 'JSON::Tiny';
    requires 'Alien::cmake3';
    requires 'Alien::git';
};
on test => sub {
    requires 'File::ShareDir';
    requires 'File::Slurp';
    requires 'File::Spec::Functions';
    requires 'JSON::Tiny';
    requires 'Test::More', '0.98';
};
on develop => sub {
    requires 'Test::Pod', '1.41';
};
on runtime => sub {
    requires 'File::ShareDir';
    requires 'File::Slurp';
    requires 'File::Spec::Functions';
    requires 'JSON::Tiny';
};
