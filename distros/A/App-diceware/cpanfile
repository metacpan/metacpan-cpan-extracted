requires 'perl', '5.01404';

requires 'File::Share', '0';
requires 'Data::Entropy', '0';
requires 'Crypt::Rijndael', '0';
requires 'Crypt::URandom', '0';
requires 'Data::Entropy::Algorithms', '0';
requires 'Data::Entropy::RawSource::CryptCounter', '0';
requires 'Data::Entropy::Source', '0';

on 'develop', sub {
    requires 'Code::TidyAll', '0';
    requires 'Perl::Tidy', '0';
    requires 'Test::Code::TidyAll', '0.20';
    requires 'Test::Perl::Critic', '0';
    requires 'Text::Diff', '0'; # undeclared Test::Code::TidyAll plugin dependency
};

on test => sub {
    requires 'Test2::V0', '0';
    requires 'Test::More', '0.96';
    requires 'Test::Script', '0';
};
