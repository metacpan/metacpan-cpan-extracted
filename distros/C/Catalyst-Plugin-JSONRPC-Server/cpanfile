requires 'perl', '5.036';
requires 'Moo';
requires 'JSON::MaybeXS';
requires 'Try::Tiny';
requires 'namespace::clean';
requires 'Carp';
requires 'Scalar::Util';
requires 'Catalyst::Runtime', '5.90000';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Fatal';
    requires 'HTTP::Request::Common';
    requires 'Moose';
};

# Author-only: t/perl_critic.t self-skips unless PERL_CRITIC_TEST is set and
# Test::Perl::Critic is installed, so it is a develop dep, not a test requirement.
on develop => sub {
    requires 'Test::Perl::Critic';
};
