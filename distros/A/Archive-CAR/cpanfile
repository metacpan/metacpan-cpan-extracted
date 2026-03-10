requires 'CBOR::Free', '0.32';
requires 'Crypt::PRNG';
requires 'Digest::SHA';
requires 'JSON::PP';
requires 'Path::Tiny';
requires 'perl', 'v5.40.0';
on configure => sub {
    requires 'Module::Build::Tiny';
};
on build => sub {
    requires 'Test2::Suite';
};
on test => sub {
    requires 'Test2::V0';
};
