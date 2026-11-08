#!/usr/bin/perl

# Data::JSEmail::make must not drop a mailbox whose email has no '@'.
# RFC 8621 S4.1.2.3: EmailAddress objects "MAY have an 'email' property
# that does not conform to the 'addr-spec' form (for example, may not
# contain an @ symbol)"; S4.6: the message "may be invalid per RFC 5322
# ... if it is a half-finished draft".  Email::MIME's address encoding
# silently drops such a mailbox, leaving an empty header.

use strict;
use warnings;
use utf8;
use Test::More;

use lib 'lib';
use Data::JSEmail;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

sub build {
  my %args = @_;
  return Data::JSEmail::make({
    bodyValues => { 1 => { value => "body\n" } },
    textBody   => [ { partId => 1 } ],
    %args,
  }, undef, sub { undef });
}

# All values of header $name in a built message, unfolded.
sub hdr {
  my ($msg, $name) = @_;
  my ($head) = split /\r\n\r\n/, $msg, 2;
  $head =~ s/\r\n[ \t]+/ /g;
  return map { /^\Q$name\E:[ \t]*(.*)$/i ? $1 : () } split /\r\n/, $head;
}

my %field = (
  from    => 'From',
  to      => 'To',
  cc      => 'Cc',
  bcc     => 'Bcc',
  replyTo => 'Reply-To',
  sender  => 'Sender',
);

for my $prop (sort keys %field) {
  my $h = $field{$prop};
  is_deeply([ hdr(build($prop => [ { email => 'user1' } ]), $h) ], [ 'user1' ],
    "$prop: bare email kept");
  is_deeply([ hdr(build($prop => [ { name => 'Name', email => 'user1' } ]), $h) ], [ 'Name <user1>' ],
    "$prop: name and bare email kept");
}

is_deeply([ hdr(build(to => [ { email => 'a@example.com' }, { email => 'user1' }, { name => 'B', email => 'b@example.com' } ]), 'To') ],
  [ 'a@example.com, user1, B <b@example.com>' ], 'mixed list keeps every mailbox, in order');

is_deeply([ hdr(build(from => [ { name => 'Jöhn Smîth', email => 'user1' } ]), 'From') ],
  [ '=?UTF-8?Q?J=C3=B6hn_Sm=C3=AEth?= <user1>' ], 'non-ASCII name is RFC 2047 encoded');

is_deeply([ hdr(build(from => [ { name => 'Al "the" Pal, Jr', email => 'al' } ]), 'From') ],
  [ '"Al \"the\" Pal, Jr" <al>' ], 'name needing quotes is a quoted-string');

# Valid addresses still go through Email::MIME, unchanged.
is_deeply([ hdr(build(from => [ { name => 'Bob', email => 'bob@example.org' } ]), 'From') ],
  [ 'Bob <bob@example.org>' ], 'valid address unchanged');
is_deeply([ hdr(build(from => [ { name => 'Al "the" Pal', email => 'al@example.org' } ]), 'From') ],
  [ '"Al \"the\" Pal" <al@example.org>' ], 'quote in a valid name is escaped');

# header:* string values, including one Email::MIME treats as an address
# list that is not a convenience property.
my $m = build(
  'header:Disposition-Notification-To' => 'user1',
  'header:To'                          => 'Friends: a@example.com, user1;',
  'header:Cc'                          => [ 'c@example.com', 'bare' ],
);
is_deeply([ hdr($m, 'Disposition-Notification-To') ], [ 'user1' ], 'header:Disposition-Notification-To kept');
is_deeply([ hdr($m, 'To') ], [ 'Friends: a@example.com, user1;' ], 'group with a bare member kept');
is_deeply([ hdr($m, 'Cc') ], [ 'c@example.com', 'bare' ], ':all values each kept');

# bodyStructure mode applies message headers the same way.
my $bs = Data::JSEmail::make({
  from          => [ { email => 'user1' } ],
  bodyStructure => { type => 'text/plain', partId => 1 },
  bodyValues    => { 1 => { value => "x\n" } },
}, undef, sub { undef });
is_deeply([ hdr($bs, 'From') ], [ 'user1' ], 'bodyStructure: bare From kept');

# ...and so does a header:* on a bodyStructure node.
my $bs2 = Data::JSEmail::make({
  bodyStructure => { type => 'text/plain', partId => 1, 'header:Reply-To' => 'user2' },
  bodyValues    => { 1 => { value => "x\n" } },
}, undef, sub { undef });
is_deeply([ hdr($bs2, 'Reply-To') ], [ 'user2' ], 'bodyStructure node header kept');

# Written raw, so a line break in a value must not start a new header.
my $inj = build(from => [ { name => "a\r\nBcc: x\@evil.example", email => 'user1' } ]);
is_deeply([ hdr($inj, 'Bcc') ], [], 'no header injected through a name');
my $inj2 = build(to => [ { email => "user1\r\nBcc: x\@evil.example" } ]);
is_deeply([ hdr($inj2, 'Bcc') ], [], 'no header injected through an email');

is_deeply(\@warnings, [], 'no warnings');

done_testing;
