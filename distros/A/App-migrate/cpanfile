requires 'perl', '5.010001';

requires 'File::Temp';
requires 'List::Util', '1.33';
requires 'Getopt::Long';

on configure => sub {
    requires 'Devel::AssertOS';
    requires 'Module::Build::Tiny', '0.039';
};

on test => sub {
    requires 'Path::Tiny', '0.060';
    requires 'Test::Exception';
    requires 'Test::More', '0.96';
    requires 'Test::Output', '1.02';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
