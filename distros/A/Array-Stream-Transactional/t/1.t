# $Id: 1.t,v 1.5 2004/04/08 19:36:28 claes Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 266 };
use Array::Stream::Transactional;
use strict;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $stream = Array::Stream::Transactional->new(["a100".."a199"]);
$stream->commit;
ok(UNIVERSAL::isa($stream, "Array::Stream::Transactional"));
ok($stream->length == 100);
ok($stream->pos == 0);
ok($stream->current eq 'a100');
ok($stream->next eq 'a101' && $stream->pos == 1);
ok($stream->commit);
ok($stream->current eq 'a101' && $stream->previous eq 'a100');
$stream->next for 1..10;
ok($stream->current eq 'a111' && $stream->previous eq 'a110' && $stream->pos == 11);
$stream->rollback;
ok($stream->pos == 1 && $stream->current eq 'a101' && $stream->previous eq 'a100');
$stream->rollback;
ok($stream->pos == 0 && $stream->current eq 'a100' && !defined $stream->previous);
ok($stream->following eq 'a101' && $stream->pos == 0);
$stream->commit;

my @compare = "a100".."a199";
while($stream->has_more) {
  ok((shift @compare) eq $stream->current);
  $stream->next;
}
$stream->rollback;
$stream->commit;

my $reverted = 0;
@compare = ("a100".."a149", "a100".."a199");

while($stream->has_more) {
  ok((shift @compare) eq $stream->current);
  if($stream->current eq "a149" && !$reverted) {
    $stream->rollback;
    $reverted = 1;
    next;
  }
  $stream->next;
}

# Run from the start again
$stream->reset;

$stream->next for 1..20;

my $p1 = $stream->pos;
my $p2 = $stream->current;
my $p3 = $stream->previous;

$stream->commit;

$stream->next for 1..20;

my ($p1v, $p2v, $p3v) = $stream->regret;

ok($p1 eq $p1v);
ok($p2 eq $p2v);
ok($p3 eq $p3v);

ok($stream->rewind eq 'a139' && $stream->pos == 39);

