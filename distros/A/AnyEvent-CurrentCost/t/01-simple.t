#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{ANYEVENT_CURRENT_COST_TEST_DEBUG}
};
use Test::More;
$ENV{PERL_ANYEVENT_MODEL} = 'Perl' unless ($ENV{PERL_ANYEVENT_MODEL});

$|=1;
use_ok('AnyEvent::CurrentCost');

my $cv = AnyEvent->condvar;
open my $fh, 't/log/envy.reading.xml';
AnyEvent::CurrentCost->new(callback => sub { print $cv->send($_[0]) },
                           filehandle => $fh,
                           on_error => sub { $cv->croak($_[1]) });
my $msg = $cv->recv;
is($msg->value, 2496, 'got correct reading');
$cv = AnyEvent->condvar;

# error as we have outstanding read requests
like(test_error(sub { $cv->recv }), qr/^Error: /, 'error');

is(test_error(sub { AnyEvent::CurrentCost->new }),
   q{AnyEvent::CurrentCost->new: 'callback' parameter is required},
   'require callback parameter');

done_testing;

sub test_error {
  eval { shift->() };
  local $_ = $@;
  s/\s+at\s.*$//s;
  $_;
}
