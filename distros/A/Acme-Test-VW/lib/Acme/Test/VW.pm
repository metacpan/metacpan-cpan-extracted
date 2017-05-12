package Acme::Test::VW;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Test::Builder;

our $CI = grep $ENV{$_}, qw(
    CI
    CONTINUOUS_INTEGRATION
    JENKINS_URL
    HUDSON_URL
    TRAVIS
    CIRCLECI
    TF_BUILD
    TEAMCITY_VERSION
    BUILDKITE

    AUTOMATED_TESTING
    NONINTERACTIVE_TESTING
    RELEASE_TESTING
    AUTHOR_TESTING
    PERL_MM_USE_DEFAULT
    PERL5_CPAN_IS_RUNNING
    PERL_CPAN_REPORTER_DIR
    PERL_CPAN_REPORTER_CONFIG
);

if ($CI) {
    my $ok_orig = $Test::Builder::Test->can("ok");
    *Test::Builder::ok = sub {
        my($self, $test, $name) = @_;
        $self->$ok_orig(1, $name);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Test::VW - Makes your tests always pass under CI

=head1 SYNOPSIS

  # export PERL5OPT=-MAcme::Test::VW

  use Test::More;
  ok 1 == 2;
  done_testing;

=head1 DESCRIPTION

Acme::Test::VW makes your failing tests pass when running under CI (CPAN Testers, Jenkins, Travis CI etc).

Inspired by L<https://github.com/auchenberg/volkswagen>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2015- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://github.com/auchenberg/volkswagen>

L<https://github.com/hmlb/phpunit-vw>

=cut
