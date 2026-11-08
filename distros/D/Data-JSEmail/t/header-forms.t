#!/usr/bin/perl

# The parsed header forms of RFC 8621 S4.1.2 and the header:{name}
# properties of S4.1.3, computed the way the proxy computes them: the Raw
# value of each instance (from the "headers" list parse() returns) handed
# to Data::JSEmail::asText, asAddresses, ... (jmap-perl
# JMAP/API/Email.pm _header_prop_value; t/lib/JSEmailTest.pm prop_value
# is a copy of it).

use strict;
use warnings;
use utf8;
use Test::More;

use lib 'lib', 't/lib';
use JSEmailTest qw(parse_fixture prop_value header_values);
use Data::JSEmail;

binmode(Test::More->builder->$_, ':encoding(UTF-8)') for qw(output failure_output todo_output);

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

sub form { my ($form, $raw) = @_; Data::JSEmail->can($form)->($raw) }

# --- S4.1.3: headers, header:{name}, :all ---------------------------------

my $plain = parse_fixture('plain.eml');
my $h = $plain->{headers};

is_deeply([ map { $_->{name} } @$h ],
  [ qw(Return-Path Received From To Cc Subject Date Message-ID In-Reply-To
       References X-Custom X-Custom MIME-Version Content-Type
       Content-Transfer-Encoding) ],
  'headers: every field, in message order, with its capitalization');

# S4.1.2.1 Raw: everything after the colon, folding kept, final CRLF not.
is(prop_value($h, 'header:Subject'), " Plain\r\n text message", 'Raw keeps the leading space and the fold');
is(prop_value($h, 'header:subject'), " Plain\r\n text message", 'names match case-insensitively');
is(prop_value($h, 'header:X-Custom'), '  second value ', 'without :all, the last instance');
is_deeply(prop_value($h, 'header:X-Custom:all'), [ ' first', '  second value ' ], ':all gives every instance in order');
is(prop_value($h, 'header:X-Missing'), undef, 'absent header is null');
is_deeply(prop_value($h, 'header:X-Missing:all'), [], 'absent header with :all is []');
is_deeply(prop_value($h, 'header:X-Custom:asText:all'), [ 'first', 'second value' ], ':asText:all');
is(prop_value($h, 'header:Received:asText'),
  "from mx.example.com (mx.example.com [192.0.2.1])\tby mail.example.org with ESMTP id 12345"
  . "\tfor <bob\@example.org>; Sat, 07 Nov 2026 10:00:00 +0000",
  'Text unfolds by removing CRLF only (RFC 5322 S2.2.3)');

# Raw is a String: RFC 6532 UTF-8 octets must come back as characters.
my $eai = parse_fixture('eai.eml');
{
  local $TODO = 'Raw header values are returned as undecoded octets (headers(), lib line 357)';
  is(prop_value($eai->{headers}, 'header:Subject'), ' Grüße — 你好', 'Raw: UTF-8 header is characters');
}
{
  my $m = Data::JSEmail::parse("X-Bad: caf\xe9 a\x00b\r\nSubject: s\r\n\r\nbody\r\n");
  local $TODO = 'Raw header values are returned as undecoded octets (headers(), lib line 357)';
  is(prop_value($m->{headers}, 'header:X-Bad'), " caf\x{fffd} ab",
    'Raw: invalid UTF-8 becomes U+FFFD (SHOULD) and NUL is dropped (MUST)');
}

# --- S4.1.2.2 Text --------------------------------------------------------

my $ew = parse_fixture('encoded-words.eml');
my $eh = $ew->{headers};
is(prop_value($eh, 'header:Subject:asText'), 'Grüße aus München',
  'Text: adjacent encoded-words in UTF-8 and ISO-8859-1 join, whitespace between them dropped');
is(prop_value($eh, 'header:Comments:asText'), '你好 world', 'Text: GB2312 encoded-word');
is(prop_value($eh, 'header:X-NFC:asText'), 'été', 'Text: result is NFC');
is(prop_value($eh, 'header:X-Unknown-Charset:asText'), '=?x-no-such-charset?Q?abc?=',
  'Text: encoded-word in an unknown charset is left alone');
is(form(asText => " =?utf-8?q?lower?="), 'lower', 'Text: charset and encoding are case-insensitive');
is(form(asText => " =?UTF-8*en?Q?lang?="), 'lang', 'Text: RFC 2231 language suffix on an encoded-word');
is(form(asText => " =?UTF-8?Q?a?=  =?UTF-8?Q?b?= c =?UTF-8?Q?d?="), 'ab c d',
  'Text: only whitespace between two encoded-words is dropped');
is(form(asText => " =?UTF-8?B?/w==?= x"), "\x{fffd} x", 'Text: malformed UTF-8 in an encoded-word becomes U+FFFD');
is(form(asText => " caf\xe9"), "caf\x{fffd}", 'Text: raw non-UTF-8 octet becomes U+FFFD');
is(form(asText => " Gr\xc3\xbc\xc3\x9fe"), 'Grüße', 'Text: raw UTF-8 octets (RFC 6532) decode');
is(prop_value($eai->{headers}, 'header:Subject:asText'), 'Grüße — 你好', 'Text: EAI subject');
{
  local $TODO = 'asText decodes encoded-word-looking text anywhere (Encode MIME-Header is lenient; lib line 235)';
  is(prop_value($eh, 'header:Keywords:asText'), 'not=?UTF-8?Q?encoded?=here',
    'Text: encoded-word not delimited by whitespace MUST NOT be decoded');
  is(form(asText => ' "=?UTF-8?Q?quoted?="'), '"=?UTF-8?Q?quoted?="',
    'Text: encoded-word glued to a quote MUST NOT be decoded');
}
{
  local $TODO = 'asText keeps NUL and control characters from encoded-words (lib line 235-241)';
  is(form(asText => " =?UTF-8?Q?a=00b=07c?="), 'abc', 'Text: encoded NUL and controls are dropped');
}

# --- S4.1.2.3 Addresses / S4.1.2.4 GroupedAddresses -----------------------

# The S4.1.2.3 example.  The RFC prints the third name as "John Smith";
# the encoded-word says "Sm=C3=AEth", which is "Smîth".
my $spec_list = qq{"  James Smythe" <james\@example.com>, Friends:\r\n  jane\@example.com, =?UTF-8?Q?John_Sm=C3=AEth?=\r\n  <john\@example.com>;};
is_deeply(form(asAddresses => $spec_list), [
  { name => 'James Smythe', email => 'james@example.com' },
  { name => undef,          email => 'jane@example.com' },
  { name => 'John Smîth',   email => 'john@example.com' },
], 'Addresses: the S4.1.2.3 example');
is_deeply(form(asGroupedAddresses => $spec_list), [
  { name => undef, addresses => [
    { name => 'James Smythe', email => 'james@example.com' } ] },
  { name => 'Friends', addresses => [
    { name => undef,        email => 'jane@example.com' },
    { name => 'John Smîth', email => 'john@example.com' } ] },
], 'GroupedAddresses: the S4.1.2.4 example');

is_deeply(form(asAddresses => q{ "Doe, \"JD\" John" <jd@example.com>}),
  [ { name => 'Doe, "JD" John', email => 'jd@example.com' } ],
  'Addresses: quoted name with a comma and quoted-pairs');
is_deeply(prop_value($plain->{headers}, 'header:Cc:asAddresses'),
  [ { name => 'Smith, Dave', email => 'dave@example.net' } ], 'Addresses: quoted comma in a fixture');
is_deeply(prop_value($eh, 'header:Cc:asAddresses'), [
  { name => 'Smith, John', email => 'john@example.com' },
  { name => 'テスト',      email => 'test@example.jp' },
], 'Addresses: an encoded comma in a phrase does not split the mailbox; Shift_JIS name');
is_deeply(prop_value($eh, 'header:From:asAddresses'),
  [ { name => 'Иван Петров', email => 'ivan@example.ru' } ], 'Addresses: KOI8-R name');
is_deeply(prop_value($eh, 'header:To:asAddresses'), [
  { name => '山田太郎', email => 'yamada@example.jp' },
  { name => 'François', email => 'francois@example.fr' },
], 'Addresses: ISO-2022-JP and windows-1252 names, folded list');
is_deeply(prop_value($eai->{headers}, 'header:To:asAddresses'),
  [ { name => '山田', email => '山田@例え.jp' } ], 'Addresses: RFC 6532 UTF-8 addr-spec');
is_deeply(form(asAddresses => ' =?UTF-8?B?w6k=?= <E@EXAMPLE.COM>'),
  [ { name => 'é', email => 'E@example.com' } ], 'Addresses: domain lower-cased, local part kept');
is_deeply(form(asAddresses => ' Undisclosed recipients:;'), [], 'Addresses: empty group gives no mailboxes');
is_deeply(form(asGroupedAddresses => ' Undisclosed recipients:;'),
  [ { name => 'Undisclosed recipients', addresses => [] } ], 'GroupedAddresses: empty group kept');
is_deeply(form(asGroupedAddresses => ' a@x.com, G: b@x.com;, c@x.com'), [
  { name => undef, addresses => [ { name => undef, email => 'a@x.com' } ] },
  { name => 'G',   addresses => [ { name => undef, email => 'b@x.com' } ] },
  { name => undef, addresses => [ { name => undef, email => 'c@x.com' } ] },
], 'GroupedAddresses: ungrouped mailboxes either side of a group');
is_deeply(form(asAddresses => ' '), [], 'Addresses: empty value is []');
{
  local $TODO = 'a trailing comment is not used as the name (asGroupAddresses uses phrase() only, lib line 320)';
  is_deeply(form(asAddresses => ' john@example.com (John Doe)'),
    [ { name => 'John Doe', email => 'john@example.com' } ], 'Addresses: comment after addr-spec SHOULD be the name');
}
{
  local $TODO = 'mailbox without a valid addr-spec is dropped (address() is undef; lib lines 269, 287, 321)';
  is_deeply(form(asAddresses => ' user1'), [ { name => undef, email => 'user1' } ],
    'Addresses: bare token with no @ is kept (S4.1.2.3 MAY)');
  is_deeply(form(asAddresses => ' Bob <bob>'), [ { name => 'Bob', email => 'bob' } ],
    'Addresses: angle-addr with no @ is kept');
}

# --- S4.1.2.5 MessageIds --------------------------------------------------

is_deeply(prop_value($plain->{headers}, 'header:References:asMessageIds'),
  [ 'grandparent@example.com', 'parent@example.com' ], 'MessageIds: folded list');
is_deeply(form(asMessageIds => ' <a@b> (comment) <c@d>'), [ 'a@b', 'c@d' ], 'MessageIds: comments removed');
is(form(asMessageIds => ' not a msgid'), undef, 'MessageIds: unparseable is null');
is(form(asMessageIds => ''), undef, 'MessageIds: empty is null');
{
  local $TODO = 'CFWS inside the angle brackets is kept (lib line 191)';
  is_deeply(form(asMessageIds => ' < a@b >'), [ 'a@b' ], 'MessageIds: CFWS removed');
}

# --- S4.1.2.6 Date --------------------------------------------------------

my %dates = (
  ' Sat, 7 Nov 2026 10:00:00 +0000'          => '2026-11-07T10:00:00Z',
  ' Sat, 07 Nov 2026 09:59:58 +1100'         => '2026-11-07T09:59:58+11:00',
  ' Sat, 07 Nov 2026 10:00:00 +0530'         => '2026-11-07T10:00:00+05:30',
  ' Sat, 07 Nov 2026 23:32 -0330'            => '2026-11-07T23:32:00-03:30',
  ' Sat, 07 Nov 2026 10:00:00 -0800 (PST)'   => '2026-11-07T10:00:00-08:00',
  ' 7 Nov 2026 10:00:00 GMT'                 => '2026-11-07T10:00:00Z',
  ' Sat, 07 Nov 2026 10:00:00 EST'           => '2026-11-07T10:00:00-05:00',
  ' Sat, 07 Nov 26 10:00:00 +0000'           => '2026-11-07T10:00:00Z',
  ' Mon, 30 Feb 2026 10:00:00 +0000'         => undef,
  ' yesterday'                               => undef,
  ' '                                        => undef,
);
for my $in (sort keys %dates) {
  is(form(asDate => $in), $dates{$in}, "Date: '$in'");
}
is(prop_value(parse_fixture('no-content-type.eml')->{headers}, 'header:Date:asDate'), undef,
  'Date: invalid Date header is null');

# --- S4.1.2.7 URLs --------------------------------------------------------

is_deeply(form(asURLs => ' <http://example.com/help>, <mailto:list@example.com?subject=help> (Help)'),
  [ 'http://example.com/help', 'mailto:list@example.com?subject=help' ], 'URLs: brackets and comments removed');
is_deeply(form(asURLs => qq{ <http://a.example/>,\r\n <mailto:b\@example.com>}),
  [ 'http://a.example/', 'mailto:b@example.com' ], 'URLs: folded list');
is(form(asURLs => ' NO (posting not allowed)'), undef, 'URLs: RFC 2369 "NO" is not a URL list');
is(form(asURLs => ' '), undef, 'URLs: empty is null');

# --- S4.1.3: each convenience property is identical to its header form ----

my %convenience = (
  messageId => 'header:Message-ID:asMessageIds',
  inReplyTo => 'header:In-Reply-To:asMessageIds',
  references => 'header:References:asMessageIds',
  sender    => 'header:Sender:asAddresses',
  from      => 'header:From:asAddresses',
  to        => 'header:To:asAddresses',
  cc        => 'header:Cc:asAddresses',
  bcc       => 'header:Bcc:asAddresses',
  replyTo   => 'header:Reply-To:asAddresses',
  subject   => 'header:Subject:asText',
  sentAt    => 'header:Date:asDate',
);
opendir my $dh, 't/data' or die $!;
for my $file (sort grep { /\.eml$/ } readdir $dh) {
  my $m = parse_fixture($file);
  for my $prop (sort keys %convenience) {
    is_deeply($m->{$prop}, prop_value($m->{headers}, $convenience{$prop}),
      "$file: $prop is $convenience{$prop}");
  }
}

# A Subject whose decoded text looks like an encoded-word.
my $tricky = Data::JSEmail::parse(join("\r\n",
  'From: a@example.com',
  'Subject: =?UTF-8?Q?=3D=3FUTF-8=3FQ=3Fx=3F=3D?=',
  'Cc: =?UTF-8?Q?=3D=3FUTF-8=3FQ=3FA=3F=3D?= <a@example.com>',
  '', 'body', ''));
is(prop_value($tricky->{headers}, 'header:Subject:asText'), '=?UTF-8?Q?x?=', 'header:Subject:asText decodes once');
{
  is_deeply(prop_value($tricky->{headers}, 'header:Cc:asAddresses'),
    [ { name => q{=?UTF-8?Q?A?=}, email => q{a@example.com} } ], q{header:Cc:asAddresses decodes the name once});
}
{
  is($tricky->{subject}, '=?UTF-8?Q?x?=', 'subject is decoded once');
  is_deeply($tricky->{cc}, [ { name => '=?UTF-8?Q?A?=', email => 'a@example.com' } ], 'cc name is decoded once');
}

is_deeply(\@warnings, [], 'no warnings');

done_testing;
