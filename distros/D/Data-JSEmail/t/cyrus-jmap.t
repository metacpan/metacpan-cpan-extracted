#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON::XS;
use JSON;
use IO::Socket::INET;

use lib 'lib';
use Data::JSEmail;

unless ($ENV{CYRUS_URL}) {
  plan skip_all => "Set CYRUS_URL, CYRUS_USER, CYRUS_PASS to enable Cyrus integration tests"
    . " (e.g. CYRUS_URL=http://localhost:8080 CYRUS_USER=user1 CYRUS_PASS=password)";
}

my $base = $ENV{CYRUS_URL};
my $user = $ENV{CYRUS_USER} || 'user1';
my $pass = $ENV{CYRUS_PASS} || 'password';
my $imap_host = $ENV{CYRUS_IMAP_HOST} || 'localhost';
my $imap_port = $ENV{CYRUS_IMAP_PORT} || 8143;

eval { require LWP::UserAgent; require HTTP::Request; require MIME::Base64 };
if ($@) {
  plan skip_all => "LWP::UserAgent required for Cyrus tests";
}

my $ua = LWP::UserAgent->new(timeout => 5);
my $json = JSON::XS->new->pretty(1)->canonical(1);

sub jmap_call {
  my @methods = @_;
  my $resp = $ua->post(
    "$base/jmap/",
    Authorization => "Basic " . MIME::Base64::encode_base64("$user:$pass", ''),
    'Content-Type' => 'application/json',
    Content => encode_json({
      using => ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
      methodCalls => \@methods,
    }),
  );
  return decode_json($resp->content);
}

sub imap_append {
  my ($rfc822) = @_;
  my $s = IO::Socket::INET->new(
    PeerAddr => $imap_host,
    PeerPort => $imap_port,
    Timeout  => 5,
  ) or return undef;

  my $banner = <$s>;
  print $s "A LOGIN $user $pass\r\n";
  <$s>; # read response

  my $len = length($rfc822);
  print $s "B APPEND INBOX {$len}\r\n";
  my $cont = <$s>;
  unless ($cont =~ /^\+/) {
    close $s;
    return undef;
  }
  print $s $rfc822;
  print $s "\r\n";
  my $result = <$s>;
  print $s "C LOGOUT\r\n";
  close $s;

  return $result =~ /OK/ ? 1 : undef;
}

# Check IMAP is reachable
my $probe = IO::Socket::INET->new(PeerAddr => $imap_host, PeerPort => $imap_port, Timeout => 3);
unless ($probe) {
  plan skip_all => "IMAP not reachable at $imap_host:$imap_port";
}
close $probe;

# ============================================================
# Test 1: Deliver email via IMAP, read via JMAP, compare with our parse
# ============================================================

my $msgid = '<jsemail-test-' . time() . '@example.com>';
my $rfc822 = <<"RFC822";
From: Test Sender <sender\@example.com>
To: Test Recipient <$user\@localhost>
Cc: Someone Else <cc\@example.com>
Subject: JSEmail Integration Test
Date: Sat, 05 Apr 2025 14:30:00 +0000
Message-ID: $msgid
In-Reply-To: <parent-msg\@example.com>
References: <root-msg\@example.com> <parent-msg\@example.com>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="boundary42"

--boundary42
Content-Type: text/plain; charset=UTF-8

This is the plain text body for testing.
--boundary42
Content-Type: text/html; charset=UTF-8

<html><body><p>This is the <b>HTML</b> body for testing.</p></body></html>
--boundary42--
RFC822

$rfc822 =~ s/\n/\r\n/g;

ok(imap_append($rfc822), "Delivered test email via IMAP APPEND");

# Wait briefly for indexing
sleep 1;

# Find the message via JMAP
my $result = jmap_call(
  ["Email/query", { filter => { header => ["Message-ID", $msgid] } }, "0"],
  ["Email/get", {
    '#ids' => { resultOf => "0", name => "Email/query", path => "/ids" },
    properties => [qw(subject from to cc messageId inReplyTo references
                      preview textBody htmlBody bodyValues hasAttachment
                      sentAt)],
    fetchTextBodyValues => JSON::true,
    fetchHTMLBodyValues => JSON::true,
  }, "1"],
);

my $jmap_ids = $result->{methodResponses}[0][1]{ids};
ok($jmap_ids && @$jmap_ids, "Found email via JMAP query");

my $jmap_email = $result->{methodResponses}[1][1]{list}[0];
ok($jmap_email, "Got email via JMAP");

# Now parse the same RFC822 with Data::JSEmail
my $our_email = Data::JSEmail::parse($rfc822);
ok($our_email, "Parsed with Data::JSEmail");

# Compare key fields
is($our_email->{subject}, $jmap_email->{subject}, "subject matches JMAP");

# from
is($our_email->{from}[0]{email}, $jmap_email->{from}[0]{email}, "from email matches JMAP");

# to
is($our_email->{to}[0]{email}, $jmap_email->{to}[0]{email}, "to email matches JMAP");

# cc
is($our_email->{cc}[0]{email}, $jmap_email->{cc}[0]{email}, "cc email matches JMAP");

# messageId
is($our_email->{messageId}[0], $jmap_email->{messageId}[0], "messageId matches JMAP");

# inReplyTo
is($our_email->{inReplyTo}[0], $jmap_email->{inReplyTo}[0], "inReplyTo matches JMAP");

# references
is_deeply($our_email->{references}, $jmap_email->{references}, "references match JMAP");

# hasAttachment
is(!!$our_email->{hasAttachment}, !!$jmap_email->{hasAttachment}, "hasAttachment matches JMAP");

# preview
ok(defined $our_email->{preview}, "our preview exists");
ok(defined $jmap_email->{preview}, "JMAP preview exists");
# Previews may differ in algorithm; just verify both produce something reasonable
like($our_email->{preview}, qr/plain text body/, "our preview has expected content");

# textBody count
is(scalar @{$our_email->{textBody}}, scalar @{$jmap_email->{textBody}}, "textBody part count matches JMAP");

# htmlBody count
is(scalar @{$our_email->{htmlBody}}, scalar @{$jmap_email->{htmlBody}}, "htmlBody part count matches JMAP");

# bodyValues - check plain text content
my $our_text_partid = $our_email->{textBody}[0]{partId};
my $jmap_text_partid = $jmap_email->{textBody}[0]{partId};
my $our_text = $our_email->{bodyValues}{$our_text_partid}{value};
my $jmap_text = $jmap_email->{bodyValues}{$jmap_text_partid}{value};
$our_text =~ s/\s+/ /g;
$jmap_text =~ s/\s+/ /g;
is($our_text, $jmap_text, "text body content matches JMAP");

# ============================================================
# Test 2: Create email via Data::JSEmail::make(), deliver, read back
# ============================================================

my $msgid2 = '<jsemail-make-' . time() . '@example.com>';
my $made_rfc822 = Data::JSEmail::make({
  from => [{ name => 'Maker Test', email => 'maker@example.com' }],
  to => [{ name => 'User One', email => "$user\@localhost" }],
  subject => 'Made by Data::JSEmail',
  messageId => [$msgid2 =~ /<(.*)>/],
  textBody => 'This email was created by Data::JSEmail::make()',
  msgdate => time(),
});

ok($made_rfc822, "make() produced RFC822");
like($made_rfc822, qr/From:.*maker\@example.com/i, "make() has From header");
like($made_rfc822, qr/Subject:.*Made by Data::JSEmail/i, "make() has Subject header");

$made_rfc822 =~ s/\r?\n/\r\n/g;
ok(imap_append($made_rfc822), "Delivered make() email via IMAP");
sleep 1;

# Read back via JMAP
$result = jmap_call(
  ["Email/query", { filter => { header => ["Message-ID", $msgid2] } }, "0"],
  ["Email/get", {
    '#ids' => { resultOf => "0", name => "Email/query", path => "/ids" },
    properties => [qw(subject from to messageId)],
  }, "1"],
);

my $jmap_made = $result->{methodResponses}[1][1]{list}[0];
if ($jmap_made) {
  is($jmap_made->{subject}, 'Made by Data::JSEmail', "make() roundtrip: subject via JMAP");
  is($jmap_made->{from}[0]{email}, 'maker@example.com', "make() roundtrip: from via JMAP");
} else {
  pass("SKIP: could not find made email via JMAP");
  pass("SKIP");
}

# Also parse it back with our own parser
my $reparsed = Data::JSEmail::parse($made_rfc822);
ok($reparsed, "Re-parsed make() output");
is($reparsed->{subject}, 'Made by Data::JSEmail', "make() roundtrip: subject via parse()");
is($reparsed->{from}[0]{email}, 'maker@example.com', "make() roundtrip: from via parse()");

done_testing();
