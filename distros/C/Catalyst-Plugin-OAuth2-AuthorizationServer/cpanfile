requires 'perl', '5.036';
requires 'Moo';
requires 'MooX::StrictConstructor';
requires 'Moo::Role';
requires 'namespace::clean';
requires 'Scalar::Util';
requires 'Crypt::JWT';
requires 'Bytes::Random::Secure';
requires 'Digest::SHA';
requires 'MIME::Base64', '3.11';
requires 'JSON::MaybeXS';
requires 'Try::Tiny';
requires 'URI';
requires 'Catalyst::Runtime', '5.90000';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Fatal';
    requires 'HTTP::Request::Common';
    requires 'Moose';
    requires 'namespace::autoclean';
};

# Author-only: t/perl_critic.t self-skips unless PERL_CRITIC_TEST is set and
# Test::Perl::Critic is installed, so it is a develop dep, not a test requirement.
on develop => sub {
    requires 'Test::Perl::Critic';
};
