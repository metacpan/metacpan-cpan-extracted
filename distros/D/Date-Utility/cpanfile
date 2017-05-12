requires 'Carp';
requires 'DateTime';
requires 'Moose';
requires 'POSIX';
requires 'Scalar::Util';
requires 'Tie::Hash::LRU';
requires 'Time::Duration::Concise::Localize', '2.5';
requires 'Time::Local';
requires 'Time::Piece';
requires 'Try::Tiny';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.48';
};

on build => sub {
    requires 'perl', '5.010000';
};

on test => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'File::Spec';
    requires 'IO::Handle';
    requires 'IPC::Open3';
    requires 'Test::CheckDeps', '0.010';
    requires 'Test::More', '0.94';
    requires 'Test::MockTime', '>= 0.15';
    requires 'Test::NoWarnings', 0;
    requires 'Test::Exception', 0;
    recommends 'CPAN::Meta', '2.120900';
};

on develop => sub {
    requires 'Devel::Cover::Report::Coveralls';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::EOL';
    requires 'Test::Mojibake';
    requires 'Test::More', '0.88';
    requires 'Test::Pod', '1.41';
    requires 'Test::Pod::Coverage', '1.08';
    requires 'Test::Pod::LinkCheck';
    requires 'Test::Synopsis';
    requires 'Test::Perl::Critic';
    requires 'Test::Version', '1';
};
