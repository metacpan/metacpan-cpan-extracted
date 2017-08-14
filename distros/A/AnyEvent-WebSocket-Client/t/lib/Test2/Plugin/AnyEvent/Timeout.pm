package Test2::Plugin::AnyEvent::Timeout;

use strict;
use warnings;
use Test2::API qw( context );
use AnyEvent;

our $timeout;

# ABSTRACT: Set a timeout for tests that use AnyEvent
# VERSION

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Plugin::AnyEvent::Timeout;
 use AnyEvent;
 
 my $cv = AnyEvent->condvar;
 $cv->recv;

=head1 DESCRIPTION

Every now and then I used to get bug reports from cpantesters that
my L<AnyEvent> based modules were getting stuck in an infinite loop.
That is not a nice thing to do!  So I woul rewrite the tests to add
a timeout and cause the test to bailout if it ran for more than 30
seconds.  This is a L<Test2> plugin that does this without the
boilerplate.

=cut

sub import
{
  return if defined $timeout;
  
  $timeout = AnyEvent->timer(
    after => 30,
    cb => sub {
      my $ctx = context();
      $ctx->bail("Test exceeded timeout of 30s");
      $ctx->release;
    },
  );
}

1;

=head1 SEE ALSO

=over4

=item L<AnyEvent>

=item L<Test2::Plugin>

=back

=cut
