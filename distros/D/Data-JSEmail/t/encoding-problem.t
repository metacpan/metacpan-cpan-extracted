#!/usr/bin/perl

# RFC 8621 S4.1.4: EmailBodyValue.isEncodingProblem "is true if malformed
# sections were found while decoding the charset, the charset was unknown,
# or the content-transfer-encoding was unknown."

use strict;
use warnings;
use Test::More;

use lib 'lib';
use Data::JSEmail;

my @parts = (
  [ 'good'               => "Content-Type: text/plain; charset=utf-8",                       "good",              0 ],
  [ 'unknown charset'    => "Content-Type: text/plain; charset=x-jmts-no-such-charset",      "unknown charset",   1 ],
  [ 'invalid UTF-8'      => "Content-Type: text/plain; charset=utf-8",                       "bad \xff\xfe bytes", 1 ],
  [ 'unknown CTE'        => "Content-Type: text/plain; charset=utf-8\r\n"
                          . "Content-Transfer-Encoding: x-jmts-no-such-encoding",             "unknown encoding",  1 ],
  [ 'unknown CTE, padded and with a parameter'
                         => "Content-Type: text/plain\r\n"
                          . "Content-Transfer-Encoding:  X-UUENCODE ; foo=bar ",              "begin 644 x",       1 ],
  [ 'known CTE, odd case and padding'
                         => "Content-Type: text/plain; charset=utf-8\r\n"
                          . "Content-Transfer-Encoding:  Quoted-Printable ",                 "caf=C3=A9",         0 ],
  [ 'known CTE with a parameter'
                         => "Content-Type: text/plain\r\n"
                          . "Content-Transfer-Encoding: 7bit; x=y",                           "seven",             0 ],
  [ 'base64'             => "Content-Type: text/plain; charset=utf-8\r\n"
                          . "Content-Transfer-Encoding: base64",                              "aGVsbG8=",          0 ],
  [ '8bit'               => "Content-Type: text/plain; charset=utf-8\r\n"
                          . "Content-Transfer-Encoding: 8bit",                                "caf\xc3\xa9",       0 ],
  [ 'binary'             => "Content-Type: text/plain; charset=utf-8\r\n"
                          . "Content-Transfer-Encoding: BINARY",                              "bin",               0 ],
);

my $raw = join("\r\n",
  'From: a@example.net',
  'To: b@example.net',
  'Subject: encoding problems',
  'MIME-Version: 1.0',
  'Content-Type: multipart/mixed; boundary="b1"',
  '',
  (map { ('--b1', $_->[1], '', $_->[2]) } @parts),
  '--b1--',
  '',
);

my $msg = Data::JSEmail::parse($raw);
my @leaves = @{ $msg->{bodyStructure}{subParts} };
is(scalar @leaves, scalar @parts, 'one leaf per part');

for my $i (0 .. $#parts) {
  my ($label, undef, undef, $want) = @{ $parts[$i] };
  my $bv = $msg->{bodyValues}{ $leaves[$i]{partId} };
  ok($bv, "$label: has a body value") or next;
  is(($bv->{isEncodingProblem} ? 1 : 0), $want, "$label: isEncodingProblem");
}

# The unknown encoding still yields the best-effort (undecoded) value.
my $bv = $msg->{bodyValues}{ $leaves[3]{partId} };
is($bv->{value}, 'unknown encoding', 'unknown CTE: value is the raw body');

# And the known ones decode.
is($msg->{bodyValues}{ $leaves[5]{partId} }{value}, "caf\x{e9}", 'quoted-printable decodes');
is($msg->{bodyValues}{ $leaves[7]{partId} }{value}, 'hello', 'base64 decodes');

# Email::MIME does not strip an RFC 822 comment from the CTE, so it does
# not decode such a part; the flag must say so rather than claim success.
my $commented = Data::JSEmail::parse(join("\r\n",
  'From: a@example.net',
  'Subject: comment',
  'MIME-Version: 1.0',
  'Content-Type: text/plain; charset=utf-8',
  'Content-Transfer-Encoding: quoted-printable (a comment)',
  '',
  'caf=C3=A9',
  '',
));
my $cv = $commented->{bodyValues}{1};
ok(($cv->{value} =~ /=C3=A9/ ? $cv->{isEncodingProblem} : !$cv->{isEncodingProblem}),
   'CTE with a comment: flagged exactly when it was not decoded');

# A single-part message with an unknown CTE.
my $single = Data::JSEmail::parse(join("\r\n",
  'From: a@example.net',
  'Subject: single',
  'MIME-Version: 1.0',
  'Content-Type: text/plain; charset=us-ascii',
  'Content-Transfer-Encoding: x-gzip64',
  '',
  'opaque',
  '',
));
ok($single->{bodyValues}{1}{isEncodingProblem}, 'single part, unknown CTE: isEncodingProblem');
like($single->{bodyValues}{1}{value}, qr/^opaque/, 'single part, unknown CTE: raw value');

# No CTE at all is not a problem.
my $plain = Data::JSEmail::parse("From: a\@example.net\r\nSubject: s\r\n\r\nhi\r\n");
ok(!$plain->{bodyValues}{1}{isEncodingProblem}, 'no CTE: no problem');

done_testing;
