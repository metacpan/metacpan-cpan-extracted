requires 'Exporter';
requires 'Carp';
requires 'Params::Validate';
requires 'List::Util';
requires 'Data::Handle';
requires 'Readonly';
requires 'perl', '5.010';

on 'build', sub {
    requires 'Module::Build', '0.30';
};

on 'test', sub {
    requires 'Data::Dumper';
    requires 'Env';
    requires 'File::Spec';
    requires 'IO::Handle';
    requires 'IPC::Open3';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Class';
    requires 'Test::Fatal';
    requires 'Test::Kwalitee', '1.21';
    requires 'Test::More', '0.88';
    requires 'Test::Pod', '1.41';
    requires 'Test::Pod::Coverage', '1.08';
    requires 'Test::Tester', '1.302111';
};

on 'configure', sub {
    requires 'ExtUtils::MakeMaker';
    requires 'Module::Build', '0.30';
};

on 'develop', sub {
    requires 'Data::Dumper';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CPAN::Changes', '0.19';
    requires 'Test::CPAN::Meta::JSON', '0.16';
    requires 'Test::Kwalitee', '1.21';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod', '1.41';
    requires 'Test::Pod::Coverage', '1.08';
};
