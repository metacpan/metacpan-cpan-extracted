requires 'perl', '5.020';
requires 'ExtUtils::MakeMaker' => '6.52';

requires 'Catalyst';
requires 'Catalyst::Runtime', '>= 5.90100';

requires 'Moose';
requires 'namespace::autoclean';
requires 'JSON::MaybeXS';
requires 'Crypt::OpenSSL::RSA', '0.35'; # for RSA signing/verification with JWT (openssl 3 support)
requires 'Crypt::PK::RSA'; # for JWK key parameter extraction in JWKS endpoint
requires 'Digest::SHA';
requires 'MIME::Base64';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
requires 'Config::General';
requires 'URI';
requires 'Try::Tiny';
requires 'Data::UUID';
requires 'Bytes::Random::Secure';
requires 'Crypt::Misc'; # for slow_eq() constant-time client secret comparison (HIGH-3)
requires 'Module::Runtime';

# Optional: install Redis::Fast (preferred) or Redis for the Redis store backend.
# These are not required unless you use Store::Redis.
feature 'redis', 'Redis store backend for multi-process (FastCGI) deployments' => sub {
    recommends 'Redis::Fast';
    recommends 'Redis';
};

on 'test' => sub {
    requires 'Test::More', '>= 0.88';
    requires 'Test::Exception';
    requires 'Test::MockObject';
    requires 'Test::Deep';
    requires 'Test::Pod::Coverage', '>= 1.04';
};
