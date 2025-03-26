# Specific dependencies
requires 'DBIx::Class' => '0.06002';
requires 'Sub::Name' => '0.04';
requires 'Encode';
requires 'Crypt::URandom';
requires 'Crypt::URandom::Token';

recommends 'Digest';
recommends 'Digest::SHA';
recommends 'Crypt::OpenPGP';
# TODO: remove once Crypt::OpenPGP is fixed
recommends 'Math::Pari';

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'DBD::SQLite';
    requires 'Dir::Self';
    requires 'File::Temp';
    requires 'File::Spec';
};

on develop => sub {
    requires 'Crypt::Eksblowfish::Bcrypt';
    requires 'DBIx::Class::TimeStamp';
};
