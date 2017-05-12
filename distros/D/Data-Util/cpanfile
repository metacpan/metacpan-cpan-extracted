requires 'XSLoader', '0.02';
requires 'perl', '5.010';

on build => sub {
    requires 'Devel::PPPort', '3.19';
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'ExtUtils::ParseXS', '3.18';
    requires 'Hash::Util::FieldHash::Compat';
    requires 'Scope::Guard';
    requires 'Test::Exception', '0.27';
    requires 'Test::More', '0.62';
};

on configure => sub {
    requires 'Module::Build::XSUtil' => '>=0.02';
};
