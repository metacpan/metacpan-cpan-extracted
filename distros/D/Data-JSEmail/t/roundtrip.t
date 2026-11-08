#!/usr/bin/perl

# make -> parse round trips: an Email built with Data::JSEmail::make the
# way the proxy calls it (jmap-perl JMAP/DB.pm create_messages: a getblob
# callback returning (type, octets), and a defaults callback), parsed back
# with Data::JSEmail::parse, must have the properties it was created with
# (RFC 8621 S4.6).

use strict;
use warnings;
use utf8;
use Test::More;

use lib 'lib', 't/lib';
use JSEmailTest qw(part_ids leaves leaf_by_id prop_value blob_store hdr);
use Data::JSEmail;
use Email::MIME;
use Encode ();

binmode(Test::More->builder->$_, ':encoding(UTF-8)') for qw(output failure_output todo_output);

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

my $PNG  = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\xff\xfe";       # binary, with bare CR, LF, NUL
my $PDF  = "%PDF-1.4\n%\xe2\xe3\xcf\xd3\n1 0 obj\n";
my $UTF8 = "Gr\xc3\xbc\xc3\x9fe aus M\xc3\xbcnchen\n";              # UTF-8 octets of "Grüße aus München\n"

my $getblob = blob_store(
  png  => [ 'image/png',       $PNG ],
  pdf  => [ 'application/pdf', $PDF ],
  utf8 => [ 'text/plain',      $UTF8 ],
  csv  => [ 'text/csv',        "a,b\n1,2\n" ],
);

# Build, then parse.  Returns (raw, parsed) or () if make died.
sub rt {
  my ($create) = @_;
  my $raw = eval { Data::JSEmail::make($create, $getblob) };
  return (undef, undef, $@) unless defined $raw;
  return ($raw, Data::JSEmail::parse($raw, 'rt'));
}

# The decoded octets of a part of a raw message, by partId.
sub part_octets {
  my ($raw, $partId) = @_;
  my $eml = Email::MIME->new($raw);
  return $eml->body if $partId eq '1' && !$eml->subparts;
  for my $n (split /\./, $partId) {
    my @sub = $eml->subparts or return undef;
    $eml = $sub[$n - 1] or return undef;
  }
  return $eml->body;
}

sub value_of {
  my ($m, $part) = @_;
  return $part && $m->{bodyValues}{ $part->{partId} } ? $m->{bodyValues}{ $part->{partId} }{value} : undef;
}

# --- shorthand: textBody from bodyValues, every address and id property ---

{
  my %addr = (
    from    => [ { name => 'Al "the" Pal', email => 'al@example.com' } ],
    to      => [ { name => 'Jöhn Smîth', email => 'john@example.com' },
                 { name => 'Smith, Dave', email => 'dave@example.net' },
                 { name => undef, email => 'carol@example.org' } ],
    cc      => [ { name => '山田', email => 'yamada@example.jp' } ],
    bcc     => [ { name => undef, email => 'hidden@example.org' } ],
    replyTo => [ { name => 'Replies', email => 'replies@example.com' } ],
    sender  => [ { name => 'Sender', email => 'sender@example.com' } ],
  );
  my ($raw, $m, $err) = rt({
    %addr,
    subject    => 'Grüße — naïve café, 你好',
    messageId  => [ 'rt-1@example.com' ],
    inReplyTo  => [ 'parent@example.com' ],
    references => [ 'grandparent@example.com', 'parent@example.com' ],
    bodyValues => { 1 => { value => "Grüße aus München — 你好世界.\nSecond line €.\n" } },
    textBody   => [ { partId => 1, type => 'text/plain', language => ['de', 'zh'] } ],
  });
  ok($m, 'shorthand text: made and parsed') or diag $err;
  for my $p (sort keys %addr) {
    is_deeply($m->{$p}, $addr{$p}, "shorthand text: $p");
  }
  is($m->{subject}, 'Grüße — naïve café, 你好', 'shorthand text: subject');
  is_deeply($m->{messageId}, [ 'rt-1@example.com' ], 'shorthand text: messageId');
  is_deeply($m->{inReplyTo}, [ 'parent@example.com' ], 'shorthand text: inReplyTo');
  is_deeply($m->{references}, [ 'grandparent@example.com', 'parent@example.com' ], 'shorthand text: references');
  ok($m->{sentAt}, 'shorthand text: a Date was generated');
  is(scalar @{ $m->{textBody} }, 1, 'shorthand text: one textBody part');
  is($m->{textBody}[0]{type}, 'text/plain', 'shorthand text: text/plain');
  is_deeply($m->{textBody}[0]{language}, [ 'de', 'zh' ], 'shorthand text: language');
  is(value_of($m, $m->{textBody}[0]), "Grüße aus München — 你好世界.\nSecond line €.\n", 'shorthand text: non-ASCII body value');
  is_deeply(part_ids($m->{htmlBody}), part_ids($m->{textBody}), 'shorthand text: htmlBody is the text part');
  is_deeply($m->{attachments}, [], 'shorthand text: no attachments');
  ok(!$m->{hasAttachment}, 'shorthand text: hasAttachment false');
  like($m->{preview}, qr/^Grüße aus München/, 'shorthand text: preview');
}

# --- addresses that are not addr-specs (S4.1.2.3, S4.6) -------------------

{
  my ($raw, $m) = rt({
    from       => [ { email => 'user1' } ],
    to         => [ { name => 'Bob', email => 'bob' } ],
    bodyValues => { 1 => { value => "x\n" } },
    textBody   => [ { partId => 1 } ],
  });
  is_deeply([ hdr($raw, 'From') ], [ 'user1' ], 'no-@ address: written as given');
  local $TODO = 'mailbox without a valid addr-spec is dropped on parse (lib lines 269, 287, 321)';
  is_deeply($m->{from}, [ { name => undef, email => 'user1' } ], 'no-@ address: bare email round-trips');
  is_deeply($m->{to}, [ { name => 'Bob', email => 'bob' } ], 'no-@ address: named round-trips');
}

# --- subject that looks like an encoded-word ------------------------------

{
  my ($raw, $m) = rt({
    subject    => 'About =?UTF-8?Q?x?= syntax',
    bodyValues => { 1 => { value => "x\n" } },
    textBody   => [ { partId => 1 } ],
  });
  is(prop_value($m->{headers}, 'header:Subject:asText'), 'About =?UTF-8?Q?x?= syntax',
    'encoded-word-looking subject: header:Subject:asText round-trips');
  is($m->{subject}, 'About =?UTF-8?Q?x?= syntax', 'encoded-word-looking subject: subject round-trips');
}

# --- sentAt ---------------------------------------------------------------

{
  my ($raw, $m) = rt({
    sentAt     => '2026-11-07T10:00:00+11:00',
    bodyValues => { 1 => { value => "x\n" } },
    textBody   => [ { partId => 1 } ],
  });
  is($m->{sentAt}, '2026-11-07T10:00:00+11:00', 'sentAt round-trips');
}

# --- shorthand: text + html + attachments ---------------------------------

{
  my ($raw, $m, $err) = rt({
    subject     => 'Both bodies',
    bodyValues  => {
      t => { value => "Café — plain\n" },
      h => { value => "<p>Café — <b>html</b></p>\n" },
    },
    textBody    => [ { partId => 't', type => 'text/plain' } ],
    htmlBody    => [ { partId => 'h', type => 'text/html' } ],
    attachments => [
      { blobId => 'pdf', type => 'application/pdf', name => 'Résumé €.pdf' },
      { blobId => 'csv', type => 'text/csv', name => 'data.csv', disposition => 'attachment' },
    ],
  });
  ok($m, 'text+html+attachments: made and parsed') or diag $err;
  is(scalar @{ $m->{textBody} }, 1, 'text+html+attachments: one textBody');
  is(scalar @{ $m->{htmlBody} }, 1, 'text+html+attachments: one htmlBody');
  is($m->{textBody}[0]{type}, 'text/plain', 'text+html+attachments: textBody is text/plain');
  is($m->{htmlBody}[0]{type}, 'text/html', 'text+html+attachments: htmlBody is text/html');
  is(value_of($m, $m->{textBody}[0]), "Café — plain\n", 'text+html+attachments: text value');
  is(value_of($m, $m->{htmlBody}[0]), "<p>Café — <b>html</b></p>\n", 'text+html+attachments: html value');
  is_deeply([ map { [ $_->{type}, $_->{name}, $_->{disposition}, $_->{size} ] } @{ $m->{attachments} } ],
    [ [ 'application/pdf', 'Résumé €.pdf', 'attachment', length $PDF ],
      # A text/* part goes out in canonical form, CRLF line ends (RFC 2046
      # S4.1.1), so its 8 octets come back as 10.
      [ 'text/csv', 'data.csv', 'attachment', 10 ] ],
    'text+html+attachments: attachments keep type, name, disposition and size');
  is(part_octets($raw, $m->{attachments}[0]{partId}), $PDF, 'text+html+attachments: pdf octets round-trip');
  ok($m->{hasAttachment}, 'text+html+attachments: hasAttachment');
}

# --- htmlBody only --------------------------------------------------------

{
  my ($raw, $m) = rt({
    bodyValues => { h => { value => "<p>Только HTML</p>" } },
    htmlBody   => [ { partId => 'h', type => 'text/html' } ],
  });
  is_deeply([ map { $_->{type} } @{ $m->{textBody} } ], [ 'text/html' ], 'html only: textBody is the HTML part');
  is_deeply(part_ids($m->{htmlBody}), part_ids($m->{textBody}), 'html only: htmlBody is the same part');
  is(value_of($m, $m->{htmlBody}[0]), "<p>Только HTML</p>", 'html only: value');
}

# --- inline cid image with an HTML body ------------------------------------

{
  my ($raw, $m) = rt({
    bodyValues  => {
      t => { value => "See the logo.\n" },
      h => { value => qq{<p>See the <img src="cid:logo\@example.com"> logo.</p>\n} },
    },
    textBody    => [ { partId => 't', type => 'text/plain' } ],
    htmlBody    => [ { partId => 'h', type => 'text/html' } ],
    attachments => [ { blobId => 'png', type => 'image/png', cid => 'logo@example.com', disposition => 'inline' } ],
  });
  my ($img) = grep { $_->{type} eq 'image/png' } leaves($m->{bodyStructure});
  ok($img, 'cid image: present');
  is($img && $img->{cid}, 'logo@example.com', 'cid image: cid');
  is($img && part_octets($raw, $img->{partId}), $PNG, 'cid image: octets round-trip');
  local $TODO = 'no multipart/related on create: the image lands in multipart/mixed and is read back as body (lib lines 1029-1044)';
  is_deeply(part_ids($m->{attachments}), [ $img && $img->{partId} ], 'cid image: read back as an attachment, not shown as body');
  is_deeply([ map { $_->{type} } @{ $m->{htmlBody} } ], [ 'text/html' ], 'cid image: htmlBody is only the HTML');
}

# --- textBody given by blobId, non-ASCII octets ----------------------------

{
  my ($raw, $m) = rt({ textBody => [ { blobId => 'utf8', type => 'text/plain' } ] });
  is(value_of($m, $m->{textBody}[0]), "Grüße aus München\n", 'textBody by blobId: UTF-8 text round-trips');
}

# --- attachment given by partId, non-ASCII bodyValue -----------------------

{
  my ($raw, $m, $err) = rt({
    bodyValues  => { 1 => { value => "body\n" }, 2 => { value => "naïve € notes\n" } },
    textBody    => [ { partId => 1 } ],
    attachments => [ { partId => 2, type => 'text/plain', name => 'notes.txt' } ],
  });
  ok($m, 'attachment by partId: made') or diag $err;
  my ($att) = @{ $m ? $m->{attachments} : [] };
  is(value_of($m, $att), "naïve € notes\n", 'attachment by partId: non-ASCII value round-trips');
}

# --- two textBody parts ----------------------------------------------------
#
# S4.6: textBody MUST contain exactly one part; such a create SHOULD be
# rejected (the proxy's _validate_email_create does), or the server MAY
# modify it.  Silently losing the second part's text is neither.

{
  my ($raw, $m, $err) = rt({
    bodyValues => { 1 => { value => "first\n" }, 2 => { value => "second\n" } },
    textBody   => [ { partId => 1, type => 'text/plain' }, { partId => 2, type => 'text/plain' } ],
  });
  my $kept = $m ? join('', map { value_of($m, $_) // '' } @{ $m->{textBody} }) : '';
  local $TODO = 'only the first textBody part is used; the second is dropped without an error (lib lines 917-932)';
  ok(!$m || ($kept =~ /first/ && $kept =~ /second/), 'two textBody parts: rejected, or both kept');
}

# --- bodyStructure ---------------------------------------------------------

{
  my $bs = {
    type => 'multipart/mixed', subParts => [
      { type => 'multipart/alternative', subParts => [
        { type => 'text/plain', partId => 't', language => ['fr'] },
        { type => 'multipart/related', subParts => [
          { type => 'text/html', partId => 'h' },
          { type => 'image/png', blobId => 'png', cid => 'logo@example.com', disposition => 'inline' },
        ] },
      ] },
      { type => 'application/pdf', blobId => 'pdf', name => 'Ünïcödé.pdf', disposition => 'attachment',
        'header:X-Part-Note' => 'kept on the part' },
    ],
  };
  my ($raw, $m, $err) = rt({
    subject       => 'Structured',
    bodyValues    => {
      t => { value => "Texte en français — €\n" },
      h => { value => qq{<p>Texte <img src="cid:logo\@example.com"> €</p>\n} },
    },
    bodyStructure => $bs,
  });
  ok($m, 'bodyStructure: made and parsed') or diag $err;

  my $shape; $shape = sub { my $n = shift; $n->{subParts} ? [ $n->{type}, map { $shape->($_) } @{ $n->{subParts} } ] : $n->{type} };
  is_deeply($shape->($m->{bodyStructure}),
    [ 'multipart/mixed', [ 'multipart/alternative', 'text/plain', [ 'multipart/related', 'text/html', 'image/png' ] ], 'application/pdf' ],
    'bodyStructure: the tree is the one given');
  is(value_of($m, leaf_by_id($m, '1.1')), "Texte en français — €\n", 'bodyStructure: text value');
  is(value_of($m, leaf_by_id($m, '1.2.1')), qq{<p>Texte <img src="cid:logo\@example.com"> €</p>\n}, 'bodyStructure: html value');
  is_deeply(leaf_by_id($m, '1.1')->{language}, ['fr'], 'bodyStructure: language');
  is(leaf_by_id($m, '1.2.2')->{cid}, 'logo@example.com', 'bodyStructure: cid');
  is(leaf_by_id($m, '1.2.2')->{disposition}, 'inline', 'bodyStructure: disposition');
  is(leaf_by_id($m, '2')->{name}, 'Ünïcödé.pdf', 'bodyStructure: non-ASCII name');
  is(prop_value(leaf_by_id($m, '2')->{headers}, 'header:X-Part-Note:asText'), 'kept on the part', 'bodyStructure: header:* on a part');
  is_deeply(part_ids($m->{textBody}), ['1.1'], 'bodyStructure: textBody');
  is_deeply(part_ids($m->{htmlBody}), ['1.2.1'], 'bodyStructure: htmlBody');
  is_deeply(part_ids($m->{attachments}), ['1.2.2', '2'], 'bodyStructure: attachments');
  {
    is(part_octets($raw, '2'), $PDF, 'bodyStructure: pdf octets round-trip');
    is(part_octets($raw, '1.2.2'), $PNG, 'bodyStructure: binary image octets round-trip');
    is(leaf_by_id($m, '1.2.2')->{size}, length $PNG, 'bodyStructure: binary image size');
  }
}

{
  my ($raw, $m) = rt({
    bodyStructure => { type => 'multipart/mixed', subParts => [
      { type => 'text/plain', blobId => 'utf8' },
      { type => 'image/png', blobId => 'png', location => 'http://example.com/logo.png' },
    ] },
  });
  {
    is(value_of($m, leaf_by_id($m, '1')), "Grüße aus München\n", 'bodyStructure: text leaf by blobId round-trips');
  }
  {
    local $TODO = 'location is never written on create (_build_bodystructure, lib lines 765-772)';
    is(leaf_by_id($m, '2')->{location}, 'http://example.com/logo.png', 'bodyStructure: location round-trips');
  }
}

{
  # A charset given with a blobId says what the octets are (S4.6 forbids
  # it only with a partId).
  my $latin1 = blob_store(l1 => [ 'text/plain', "Gr\xfc\xdfe\n" ]);
  my $raw = Data::JSEmail::make({ bodyStructure => { type => 'text/plain', blobId => 'l1', charset => 'iso-8859-1' } }, $latin1);
  my $m = Data::JSEmail::parse($raw);
  is($m->{bodyValues}{1}{value}, "Grüße\n", 'bodyStructure: ISO-8859-1 blob with its charset reads back as text');
}

# --- the leaf-part encoder: every kind of content, every list --------------

{
  my $long = ('x' x 1200) . "\n";
  my $msg  = "Subject: inner\r\nFrom: a\@example.com\r\n\r\nInner body \xc3\xa9\r\n";
  my $store = blob_store(
    png   => [ 'image/png', $PNG ],
    l1    => [ 'text/plain; charset=iso-8859-1', "caf\xe9\n" ],
    junk  => [ 'text/plain', "caf\xe9\n" ],
    long  => [ 'text/plain', $long ],
    msg   => [ 'message/rfc822', $msg ],
  );
  my $raw = Data::JSEmail::make({
    bodyValues  => { 1 => { value => "body\n" }, j => { value => qq{{"k":"vä€"}} } },
    textBody    => [ { partId => 1 } ],
    attachments => [
      { blobId => 'png', type => 'image/png', name => 'a.png' },
      { blobId => 'l1', type => 'text/plain', name => 'l1.txt' },
      { blobId => 'junk', type => 'text/plain', name => 'junk.txt' },
      { blobId => 'long', type => 'text/plain', name => 'long.txt' },
      { blobId => 'msg', type => 'message/rfc822' },
      { partId => 'j', type => 'application/json', name => 'v.json' },
    ],
  }, $store);
  my $m = Data::JSEmail::parse($raw);
  my %att = map { ($_->{name} // $_->{type}) => $_ } @{ $m->{attachments} };
  is(part_octets($raw, $att{'a.png'}{partId}), $PNG, 'leaf encoder: binary attachment octets round-trip');
  is($m->{bodyValues}{ $att{'l1.txt'}{partId} }{value}, "café\n", 'leaf encoder: the blob type gives the charset');
  ok(defined $att{'junk.txt'}, 'leaf encoder: a text blob in no known charset is still written');
  is(part_octets($raw, $att{'long.txt'}{partId}), $long =~ s/\n/\r\n/r, 'leaf encoder: a line over 998 octets survives (quoted-printable)');
  ok(!grep({ length > 998 } split /\r\n/, $raw), 'leaf encoder: no line over 998 octets');
  is(part_octets($raw, $att{'message/rfc822'}{partId}), $msg, 'leaf encoder: message/rfc822 octets round-trip');
  is(part_octets($raw, $att{'v.json'}{partId}), Encode::encode('UTF-8', qq{{"k":"vä€"}}),
    'leaf encoder: a non-text bodyValues part is its UTF-8 octets');
}

# --- header:{name} values on create ---------------------------------------

{
  my ($raw, $m) = rt({
    'header:X-Plain'  => 'simple',
    'header:X-Multi'  => [ 'one', 'two' ],
    bodyValues => { 1 => { value => "x\n" } },
    textBody   => [ { partId => 1 } ],
  });
  is(prop_value($m->{headers}, 'header:X-Plain:asText'), 'simple', 'header:X-Plain set');
  is_deeply(prop_value($m->{headers}, 'header:X-Multi:asText:all'), [ 'one', 'two' ], 'header:X-Multi as a list sets every instance');
}

{
  # S4.1.2.1: a Raw value is everything after the colon, normally with
  # the leading space, and is written as given.
  my ($raw, $m) = rt({
    'header:X-Raw' => ' raw  value',
    bodyValues => { 1 => { value => "x\n" } },
    textBody   => [ { partId => 1 } ],
  });
  is(prop_value($m->{headers}, 'header:X-Raw'), ' raw  value', 'header:X-Raw: Raw value written as given');
}

# The typed forms (S4.1.3 header:{name}:as{form}[:all]) on create, which
# make takes directly (format_header writes each).
my @typed = (
  [ 'header:X-Text:asText'                => 'Grüße, world',                                   'Grüße, world' ],
  [ 'header:X-Addrs:asAddresses'          => [ { name => 'A "q" B', email => 'ab@example.com' }, { name => undef, email => 'c@example.com' } ] ],
  [ 'header:X-Groups:asGroupedAddresses'  => [ { name => 'Team', addresses => [ { name => 'D', email => 'd@example.com' } ] } ] ],
  [ 'header:X-Ids:asMessageIds'           => [ 'a@example.com', 'b@example.com' ] ],
  [ 'header:X-When:asDate'                => '2026-11-07T10:00:00Z' ],
  [ 'header:List-Unsubscribe:asURLs'      => [ 'https://example.com/unsub', 'mailto:unsub@example.com' ] ],
  [ 'header:X-Texts:asText:all'           => [ 'one', 'twö' ] ],
  [ 'header:X-Raws:all'                   => [ ' one', ' two' ] ],
);
for my $t (@typed) {
  my ($prop, $value) = @$t;
  my ($raw, $m, $err) = rt({
    $prop      => $value,
    bodyValues => { 1 => { value => "x\n" } },
    textBody   => [ { partId => 1 } ],
  });
  is_deeply($m ? prop_value($m->{headers}, $prop) : "died: $err", $value, "$prop round-trips");
}

is_deeply(\@warnings, [], 'no warnings');

done_testing;
