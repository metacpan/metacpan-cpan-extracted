package Argon::Test;
# ABSTRACT: Utilities used by Argon's tests
$Argon::Test::VERSION = '0.18';
use strict;
use warnings;
use Test2::Bundle::Extended;
use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Util;
use Argon::Channel;
use Argon::SecureChannel;
use Const::Fast;

use parent 'Exporter';

our @EXPORT = qw(
  ar_test
  channel_pair
  secure_channel_pair
);

const our $DEFAULT_TIMEOUT => 30;
const our $KEY => 'how now brown bureaucrat';

sub ar_test {
  my $name    = shift;
  my $code    = pop;
  my $timeout = shift || $DEFAULT_TIMEOUT;

  subtest $name => sub {
    my $cv = AnyEvent->condvar;
    my $guard = AnyEvent::Util::guard { $cv->send };

    my $timer = AnyEvent->timer(
      after => $timeout,
      cb => sub { $cv->croak("Failsafe timeout triggered after $timeout seconds") },
    );

    $code->($cv);

    undef $timer;
  };
}

sub channel_pair {
  my ($cb1, $cb2) = @_;
  $cb1 ||= {};
  $cb2 ||= {};

  my ($fh1, $fh2) = AnyEvent::Util::portable_socketpair;
  AnyEvent::Util::fh_nonblocking($fh1, 1);
  AnyEvent::Util::fh_nonblocking($fh2, 1);

  my $ch1 = Argon::Channel->new(fh => $fh1, %$cb1);
  my $ch2 = Argon::Channel->new(fh => $fh2, %$cb2);

  return ($ch1, $ch2);
}

sub secure_channel_pair {
  my ($cb1, $cb2) = @_;
  $cb1 ||= {};
  $cb2 ||= {};

  my ($fh1, $fh2) = AnyEvent::Util::portable_socketpair;
  AnyEvent::Util::fh_nonblocking($fh1, 1);
  AnyEvent::Util::fh_nonblocking($fh2, 1);

  my $ch1 = Argon::SecureChannel->new(key => $KEY, fh => $fh1, %$cb1);
  my $ch2 = Argon::SecureChannel->new(key => $KEY, fh => $fh2, %$cb2);

  return ($ch1, $ch2);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Test - Utilities used by Argon's tests

=head1 VERSION

version 0.18

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
