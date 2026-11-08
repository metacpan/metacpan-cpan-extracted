#!/usr/bin/perl

# The public header-forms codec: header_value (get), format_header
# (create, its inverse), header_form_allowed (the RFC 8621 S4.1.2
# table), header_property / parse_header_property, and make() taking
# header:{name}:as{form}[:all] properties directly.

use strict;
use warnings;
use utf8;
use Test::More;

use lib 'lib', 't/lib';
use JSEmailTest qw(hdr);
use Data::JSEmail;

binmode(Test::More->builder->$_, ':encoding(UTF-8)') for qw(output failure_output todo_output);

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

*hv  = \&Data::JSEmail::header_value;
*fmt = \&Data::JSEmail::format_header;

# --- header_value ----------------------------------------------------------

is(hv(asText => [ ' a', ' =?UTF-8?Q?b=C3=BC?=' ]), 'bü', 'header_value: the last instance');
is_deeply(hv(asText => [ ' a', ' b' ], all => 1), [ 'a', 'b' ], 'header_value: all => 1 gives every instance');
is(hv(asText => []), undef, 'header_value: no instance is null');
is_deeply(hv(asText => [], all => 1), [], 'header_value: no instance with all is []');
is(hv(undef, [ ' raw ' ]), ' raw ', 'header_value: undef form is Raw');
is(hv(asRaw => [ ' raw ' ]), ' raw ', 'header_value: asRaw');
is(hv(Raw => ' one'), ' one', 'header_value: a single Raw value need not be a list');
is_deeply(hv(asAddresses => ' "A, B" <ab@example.com>'), [ { name => 'A, B', email => 'ab@example.com' } ], 'header_value: asAddresses');
ok(!eval { hv(asNothing => [ ' x' ]); 1 }, 'header_value: unknown form dies');
like($@, qr/Unknown header form 'asNothing'/, 'header_value: ... saying so');

# --- header_property / parse_header_property -------------------------------

my $headers = [ { name => 'To', value => ' a@example.com' }, { name => 'to', value => ' b@example.com' } ];
is_deeply(Data::JSEmail::header_property($headers, 'header:TO:asAddresses'),
  [ { name => undef, email => 'b@example.com' } ], 'header_property: names match case-insensitively, last instance');
is_deeply(Data::JSEmail::header_property($headers, 'header:to:all'), [ ' a@example.com', ' b@example.com' ], 'header_property: Raw :all');
is_deeply([ Data::JSEmail::parse_header_property('header:List-Post:asURLs:all') ], [ 'List-Post', 'asURLs', 1 ], 'parse_header_property: name, form, all');
is_deeply([ Data::JSEmail::parse_header_property('header:X-A') ], [ 'X-A', 'asRaw', 0 ], 'parse_header_property: Raw by default');
is_deeply([ Data::JSEmail::parse_header_property($_) ], [], "parse_header_property: '$_' is not one")
  for 'header:X:all:asText', 'header:X:asBogus', 'header:', 'header:X Y', 'subject';

# --- header_form_allowed ---------------------------------------------------

my @allowed = (
  [ Subject => 'asText', 1 ], [ Subject => 'asAddresses', 0 ], [ subject => undef, 1 ],
  [ From => 'asAddresses', 1 ], [ From => 'asGroupedAddresses', 1 ], [ From => 'asText', 0 ],
  [ 'Message-ID' => 'asMessageIds', 1 ], [ 'Message-ID' => 'asDate', 0 ],
  [ Date => 'asDate', 1 ], [ 'Resent-Date' => 'asDate', 1 ], [ Date => 'asText', 0 ],
  [ 'List-Post' => 'asURLs', 1 ], [ 'List-Post' => 'asText', 0 ],
  [ 'List-Id' => 'asText', 1 ], [ Received => 'asText', 0 ], [ Received => 'asRaw', 1 ],
  [ 'X-Anything' => 'asDate', 1 ], [ 'X-Anything' => 'asGroupedAddresses', 1 ],
  [ 'X-Anything' => 'asNothing', 0 ],
);
for my $a (@allowed) {
  my ($f, $form, $ok) = @$a;
  is(Data::JSEmail::header_form_allowed($f, $form), $ok, "header_form_allowed($f, " . ($form // 'undef') . ") is $ok");
}

# --- format_header: inverse of header_value --------------------------------

my @rt = (
  [ asText => 'plain words' ],
  [ asText => 'Grüße — naïve café, 你好' ],
  [ asText => 'About =?UTF-8?Q?x?= syntax' ],
  [ asText => "two\nlines" , "two lines" ],
  [ asAddresses => [ { name => 'Al "the" Pal, Jr', email => 'al@example.com' },
                     { name => 'Jöhn Smîth', email => 'john@example.com' },
                     { name => '=?UTF-8?Q?A?=', email => 'a@example.com' },
                     { name => 'back\\slash', email => 'b@example.com' },
                     { name => undef, email => 'c@example.com' } ] ],
  [ asAddresses => [ { name => '山田', email => '山田@例え.jp' } ] ],
  [ asAddresses => [ { name => undef, email => '"john doe"@example.com' } ] ],
  [ asAddresses => [] ],
  [ asGroupedAddresses => [ { name => undef, addresses => [ { name => 'A', email => 'a@x.com' } ] },
                            { name => 'Friends, "old"', addresses => [ { name => undef, email => 'b@x.com' },
                                                                      { name => 'Ç', email => 'c@x.com' } ] },
                            { name => 'Empty', addresses => [] } ] ],
  [ asMessageIds => [ 'a@example.com', 'b.c@example.org' ] ],
  [ asDate => '2026-11-07T10:00:00Z' ],
  [ asDate => '2026-11-07T10:00:00+11:00' ],
  [ asDate => '2026-11-07T23:32:05-03:30' ],
  [ asDate => '2026-11-07t10:00:00.123z', '2026-11-07T10:00:00Z' ],
  [ asURLs => [ 'https://example.com/a?b=c,d', 'mailto:x@example.com' ] ],
  [ asRaw => ' as  given ' ],
);
for my $t (@rt) {
  my ($form, $value, $want) = @$t;
  my $raw = fmt($form, $value);
  my $label = "format_header $form " . (ref $value ? scalar(@$value) . ' items' : "'$value'");
  ok(defined $raw && $raw !~ /\r?\n(?![ \t])/, "$label: one header line (folds only)");
  is_deeply(hv($form, [ $raw ]), $want // $value, "$label: header_value reads it back");
}

is(fmt(asText => 'x'), ' x', 'format_header: a Raw value, with the leading space');
is(fmt(asRaw => 'x'), 'x', 'format_header: asRaw is as given');
is(fmt(asDate => '2026-11-07T10:00:00+11:00'), ' Sat, 07 Nov 2026 10:00:00 +1100', 'format_header: RFC 5322 date');
is(fmt(asAddresses => [ { name => 'Smith, Dave', email => 'd@x.com' }, { email => 'user1' } ]),
  ' "Smith, Dave" <d@x.com>, user1', 'format_header: quoted name; email without @ as given');
is(fmt(asAddresses => [ { email => 'john doe@example.com' } ]), ' "john doe"@example.com',
  'format_header: a local part that is not a dot-atom is quoted');
is(fmt(asGroupedAddresses => [ { name => 'G', addresses => [] } ]), ' G:;', 'format_header: empty group');
is(fmt(asText => undef), undef, 'format_header: null is no header');
is(fmt(asMessageIds => []), undef, 'format_header: no message ids is no header');
is(fmt(asURLs => []), undef, 'format_header: no URLs is no header');

my @bad = (
  [ asDate => '2026-11-07 10:00:00' ], [ asDate => '2026-02-30T10:00:00Z' ], [ asDate => 'Sat, 07 Nov 2026 10:00:00 +0000' ],
  [ asMessageIds => [ 'a b@x' ] ], [ asMessageIds => [ '<a@x>' ] ], [ asMessageIds => 'a@x' ],
  [ asURLs => [ 'http://x/ y' ] ], [ asAddresses => { email => 'a@x' } ], [ asAddresses => [ { name => 'n' } ] ],
  [ asAddresses => [ { email => 'a@ex ample.com' } ] ],
  [ asGroupedAddresses => [ { email => 'a@x' } ] ], [ asText => [ 'x' ] ],
  [ asRaw => " a\r\nBcc: x\@evil.example" ], [ asRaw => "a\0b" ], [ asNothing => 'x' ],
);
for my $b (@bad) {
  my ($form, $value) = @$b;
  ok(!eval { fmt($form, $value); 1 }, "format_header $form dies on a bad value") or diag explain $value;
}

# --- make: typed header properties -----------------------------------------

sub build {
  my %args = @_;
  return Data::JSEmail::make({
    bodyValues => { 1 => { value => "body\n" } },
    textBody   => [ { partId => 1 } ],
    %args,
  }, undef, sub { undef });
}

is_deeply([ hdr(build('header:From:asAddresses' => [ { name => 'Jöhn "J" Smîth', email => 'j@example.com' } ]), 'From') ],
  [ '=?UTF-8?Q?J=C3=B6hn_=22J=22_Sm=C3=AEth?= <j@example.com>' ], 'make: header:From:asAddresses RFC 2047-encodes a non-ASCII name');
is_deeply([ hdr(build('header:To:asGroupedAddresses' => [ { name => 'Team', addresses => [ { email => 'a@x.com' } ] } ]), 'To') ],
  [ 'Team: a@x.com;' ], 'make: header:To:asGroupedAddresses writes a group');
is_deeply([ hdr(build('header:Date:asDate' => '2026-11-07T10:00:00Z'), 'Date') ],
  [ 'Sat, 07 Nov 2026 10:00:00 +0000' ], 'make: header:Date:asDate');
is_deeply([ hdr(build('header:Resent-To:asAddresses:all' => [ [ { email => 'a@x.com' } ], [ { email => 'b@x.com' } ] ]), 'Resent-To') ],
  [ 'a@x.com', 'b@x.com' ], 'make: :all writes one field per item');
is_deeply([ hdr(build('header:From:asAddresses' => [ { email => 'h@x.com' } ], from => [ { email => 'c@x.com' } ]), 'From') ],
  [ 'h@x.com' ], 'make: a header:* property wins over the convenience property');

for my $bad ([ 'header:Subject:asAddresses' => [] ], [ 'header:From:asText' => 'x' ],
             [ 'header:X:asText:all' => 'x' ], [ 'header:X:asBogus' => 'x' ],
             [ sentAt => 'yesterday' ]) {
  ok(!eval { build(@$bad); 1 }, "make dies on $bad->[0] => " . (ref $bad->[1] ? 'list' : $bad->[1]));
}

is_deeply(\@warnings, [], 'no warnings');

done_testing;
