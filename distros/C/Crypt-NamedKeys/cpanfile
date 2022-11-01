requires 'Carp';
# Crypt::CBC v3.01 will deprecate opensslv1 PBKDF, which is used in the code
# Maybe we need to change our code to upgrade this dep
requires 'Crypt::CBC', '<= 2.37';
requires 'Crypt::Rijndael';
requires 'Digest::SHA';
requires 'JSON::MaybeXS';
requires 'MIME::Base64';
requires 'Moo';
requires 'String::Compare::ConstantTime';
requires 'YAML::XS';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Differences';
    requires 'Test::Most';
    requires 'Test::NoWarnings';
};
