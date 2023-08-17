requires 'Locale::Country', 3.74;
requires 'Carp', 1.50;
requires 'DateTime', 1.59;
requires 'Scalar::Util', 1.63;
requires 'Env', 1.04;
requires 'Try::Tiny', 0.31;
requires 'JSON', 4.10;
requires 'File::Slurp', 9999.32;
requires 'Module::Load', 0.36;
requires 'perl', '5.006';

on 'build', sub {
    requires 'Module::Build', '0.4234';
};

on 'configure', sub {
    requires 'ExtUtils::MakeMaker';
    requires 'Module::Build', '0.4234';
};

on test => sub {
    requires 'Test::Class', 0.52;
    requires 'Test::More', 1.302195;
    requires 'FindBin', 1.53;
    requires 'Test::MockModule', '0.13';
    requires 'Test::Pod::Coverage', 1.10;
    requires 'Test::Kwalitee', '1.28';
    requires 'Test::Fatal', 0.017;
    requires 'Test::Pod', 1.52;
    requires 'Pod::Coverage::TrustPod', 0.100006;
};
