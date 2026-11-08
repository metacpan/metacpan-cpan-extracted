#!/usr/bin/perl

# Parsing the t/data corpus: bodyStructure, the EmailBodyPart properties,
# bodyValues, and the RFC 8621 S4.1.4 decomposition into textBody,
# htmlBody and attachments, with preview and hasAttachment consistent
# with that decomposition.

use strict;
use warnings;
use utf8;
use Test::More;

use lib 'lib', 't/lib';
use JSEmailTest qw(fixture parse_fixture part_ids leaves leaf_by_id);
use Data::JSEmail;

binmode(Test::More->builder->$_, ':encoding(UTF-8)') for qw(output failure_output todo_output);

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

# --- invariants every parsed message must satisfy -------------------------

sub is_media { $_[0]{type} =~ m{^(?:image|audio|video)/}i }

# S4.1.4: attachments is, depth first, every leaf not in textBody or
# htmlBody, and every image/audio/video leaf not in both.
sub expected_attachments {
  my ($m) = @_;
  my %t = map { $_ => 1 } @{ part_ids($m->{textBody}) };
  my %h = map { $_ => 1 } @{ part_ids($m->{htmlBody}) };
  return [ map { $_->{partId} }
           grep { my $id = $_->{partId};
                  (!$t{$id} && !$h{$id}) || (is_media($_) && !($t{$id} && $h{$id})) }
           leaves($m->{bodyStructure}) ];
}

# The text a reader sees first: the textBody parts, HTML stripped.
sub body_text {
  my ($m) = @_;
  my @text;
  for my $p (@{ $m->{textBody} }) {
    my $v = $m->{bodyValues}{ $p->{partId} } or next;
    push @text, $p->{type} eq 'text/html' ? Data::JSEmail::htmltotext($v->{value}) : $v->{value};
  }
  return norm(join ' ', @text);
}
sub norm { my $s = shift // ''; $s =~ s/\s+/ /g; $s =~ s/^ | $//g; $s }

# attachment-first.eml: an attachment comes before the body text.
our $PREVIEW_TODO = q{preview walks the MIME tree for the first text part, ignoring the classification (preview(), lib lines 391-407)};

sub check_invariants {
  my ($file, $m) = @_;
  for my $l (leaves($m->{bodyStructure})) {
    ok(defined $l->{partId} && defined $l->{blobId}, "$file: leaf $l->{type} has partId and blobId");
  }
  my @multi = grep { $_->{subParts} } _all_nodes($m->{bodyStructure});
  ok(!grep({ defined $_->{partId} || defined $_->{blobId} } @multi), "$file: multiparts have null partId and blobId");
  for my $list (qw(textBody htmlBody attachments)) {
    ok(!grep({ $_->{subParts} } @{ $m->{$list} }), "$file: $list holds no multiparts");
  }
  for my $list (qw(textBody htmlBody)) {
    my @bad = grep { $_->{type} !~ m{^(?:text/plain|text/html|image/|audio/|video/)}i } @{ $m->{$list} };
    ok(!@bad, "$file: $list is only text/plain, text/html and media") or diag explain [ map { $_->{type} } @bad ];
  }
  is_deeply(part_ids($m->{attachments}), expected_attachments($m), "$file: attachments are what textBody/htmlBody leave out");

  my $has = grep { ($_->{disposition} // '') ne 'inline' } @{ $m->{attachments} };
  is(($m->{hasAttachment} ? 1 : 0), ($has ? 1 : 0), "$file: hasAttachment matches the attachments list");

  ok(length($m->{preview} // '') <= 256, "$file: preview is at most 256 characters");
  my $preview = norm($m->{preview});
  my $text = body_text($m);
  local $TODO = $PREVIEW_TODO if $file eq q{attachment-first.eml};
  ok(index($text, $preview) == 0, "$file: preview is taken from the textBody")
    or diag "preview: '$preview'\ntextBody: '" . substr($text, 0, 80) . "'";
}

sub _all_nodes { my $n = shift; ($n, map { _all_nodes($_) } @{ $n->{subParts} || [] }) }

# --- the corpus -----------------------------------------------------------
#
# For each message: the textBody, htmlBody and attachments partIds the
# S4.1.4 algorithm gives, and the properties of selected leaves.

my %corpus = (
  'plain.eml' => {
    text => ['1'], html => ['1'], att => [],
    leaves => { 1 => { type => 'text/plain', charset => 'us-ascii', size => 48 } },
    values => { 1 => "Hello Bob,\n\nThis is a   plain\ntext message.\n" },
  },
  'alternative.eml' => {
    text => ['1'], html => ['2'], att => [],
    leaves => {
      1 => { type => 'text/plain', charset => 'utf-8', size => 32 },
      2 => { type => 'text/html',  charset => 'utf-8' },
    },
    values => {
      1 => "Café au lait, s'il vous plaît.",
      2 => "<html><body><p>Café <b>au lait</b>, s'il vous plaît.</p></body></html>",
    },
  },
  'mixed-attachments.eml' => {
    # 4 is text/plain with a name and not first: an attachment.  5 is an
    # inline image outside any alternative: shown in both bodies.
    text => ['1', '5'], html => ['1', '5'], att => ['2', '3', '4'],
    leaves => {
      2 => { type => 'application/pdf', name => 'report.pdf', disposition => 'attachment', size => 19, charset => undef },
      3 => { type => 'image/png', name => 'photo.png', disposition => 'attachment', size => 8 },
      4 => { type => 'text/plain', name => 'notes.txt', disposition => undef },
      5 => { type => 'image/gif', disposition => 'inline', name => undef },
    },
  },
  'related.eml' => {
    text => ['1'], html => ['2.1'], att => ['2.2', '2.3'],
    leaves => {
      '2.2' => { type => 'image/png', cid => 'logo@example.com', disposition => 'inline' },
      '2.3' => { type => 'image/gif', cid => 'chart@example.com', name => 'chart.gif',
                 location => 'http://example.com/chart.gif' },
    },
  },
  'rfc822.eml' => {
    # S4.1.4: bodyStructure does not recurse into message/rfc822.
    text => ['1'], html => ['1'], att => ['2'],
    leaves => { 2 => { type => 'message/rfc822', disposition => 'inline', charset => undef } },
    values => { 1 => 'Forwarding this.' },
  },
  'spec-4-1-4.eml' => {
    # The S4.1.4 example: A=1, B=2.1.1.1, C=2.1.1.2, D=2.1.1.3, E=2.1.2.1,
    # F=2.1.2.2, G=2.2, H=2.3, J=2.4, K=3.
    #   textBody    => [ A, B, C, D, K ]
    #   htmlBody    => [ A, E, K ]
    #   attachments => [ C, F, G, H, J ]
    text => [ '1', '2.1.1.1', '2.1.1.2', '2.1.1.3', '3' ],
    html => [ '1', '2.1.2.1', '3' ],
    att  => [ '2.1.1.2', '2.1.2.2', '2.2', '2.3', '2.4' ],
    leaves => {
      '2.1.2.2' => { type => 'image/jpeg', cid => 'f@example.com' },
      '2.2'     => { type => 'image/jpeg', disposition => 'attachment' },
      '2.3'     => { type => 'application/x-excel' },
      '2.4'     => { type => 'message/rfc822' },
    },
  },
  'encoded-words.eml' => {
    text => ['1'], html => ['1'], att => [],
    leaves => { 1 => { charset => 'iso-8859-1', size => 8 } },
    values => { 1 => "Grüße.\n" },
  },
  'rfc2231.eml' => {
    text => ['1'], html => ['1'], att => ['2', '3', '4', '5'],
    leaves => {
      2 => { name => '€ rates.txt' },
      3 => { name => 'Grüße_aus_München.pdf' },
      4 => { name => 'résumé.pdf' },          # RFC 2047 in Content-Type name
      5 => { name => 'plain name.bin' },      # filename wins over name
    },
  },
  'eai.eml' => {
    text => ['1'], html => ['1'], att => [],
    values => { 1 => "Grüße aus München — 你好世界.\n" },
    leaves => { 1 => { size => 40 } },
  },
  'html-only.eml' => {
    text => ['1'], html => ['1'], att => [],
    leaves => { 1 => { type => 'text/html' } },
  },
  'attachment-first.eml' => {
    text => ['2'], html => ['2'], att => ['1'],
  },
  'alternative-html-only.eml' => {
    # An alternative with HTML and no text/plain: the HTML is also the text.
    text => ['1.1'], html => ['1.1'], att => ['1.2'],
  },
  'unknown-charset.eml' => {
    text => ['1'], html => ['1'], att => [],
    leaves => { 1 => { charset => 'x-no-such-charset' } },
    values => { 1 => "Plain ASCII under an unknown charset.\n" },
    problem => { 1 => 1 },
  },
  'unknown-cte.eml' => {
    text => ['1'], html => ['1'], att => [],
    values => { 1 => "begin 644 x\n" },
    problem => { 1 => 1 },
  },
  'no-content-type.eml' => {
    # No Content-Type: implicitly text/plain; charset=us-ascii.
    text => ['1'], html => ['1'], att => [],
    leaves => { 1 => { type => 'text/plain', charset => 'us-ascii' } },
    sentAt => undef,
  },
);

for my $file (sort keys %corpus) {
  my $want = $corpus{$file};
  my $m = parse_fixture($file);
  is_deeply(part_ids($m->{textBody}), $want->{text}, "$file: textBody");
  is_deeply(part_ids($m->{htmlBody}), $want->{html}, "$file: htmlBody");
  is_deeply(part_ids($m->{attachments}), $want->{att}, "$file: attachments");
  for my $id (sort keys %{ $want->{leaves} || {} }) {
    my $leaf = leaf_by_id($m, $id);
    ok($leaf, "$file: part $id exists") or next;
    my %got = map { $_ => $leaf->{$_} } keys %{ $want->{leaves}{$id} };
    is_deeply(\%got, $want->{leaves}{$id}, "$file: part $id properties");
  }
  for my $id (sort keys %{ $want->{values} || {} }) {
    is($m->{bodyValues}{$id}{value}, $want->{values}{$id}, "$file: bodyValue $id");
    is(($m->{bodyValues}{$id}{isEncodingProblem} ? 1 : 0), $want->{problem}{$id} // 0,
      "$file: bodyValue $id isEncodingProblem");
  }
  is($m->{size}, length(fixture($file)), "$file: size is the octets of the message");
  check_invariants($file, $m);
}

# Specific expectations the table does not express.

{
  my $m = parse_fixture('rfc822.eml');
  my ($inner) = fixture('rfc822.eml') =~ m{Content-Disposition: inline\r\n\r\n(.*?)\r\n--fwd--}s;
  is(leaf_by_id($m, '2')->{size}, length($inner), 'rfc822.eml: message/rfc822 size is the embedded message');
  ok(!grep({ $_->{value} =~ /INNER/ } values %{ $m->{bodyValues} }), 'rfc822.eml: no body value from inside the attached message');
  is($m->{subject}, 'Fwd: Inner subject', 'rfc822.eml: subject is the outer one');
}

{
  my $m = parse_fixture('mixed-attachments.eml');
  ok($m->{hasAttachment}, 'mixed-attachments.eml: hasAttachment');
  ok(!parse_fixture('alternative.eml')->{hasAttachment}, 'alternative.eml: no attachment');
  ok(!parse_fixture('plain.eml')->{hasAttachment}, 'plain.eml: no attachment');
  is(parse_fixture('plain.eml')->{preview} =~ s/\s+$//r, 'Hello Bob, This is a plain text message.',
    'plain.eml: preview collapses whitespace');
  like(parse_fixture(q{html-only.eml})->{preview}, qr{^Only\s+HTML here\.\s*$},
    'html-only.eml: preview is the HTML as text');
}

{
  # Every corpus file is covered above or below.
  opendir my $dh, 't/data' or die $!;
  my @files = sort grep { /\.eml$/ } readdir $dh;
  my @missing = grep { !$corpus{$_} && !/^(?:digest|bad-boundary)\.eml$/ } @files;
  is_deeply(\@missing, [], 'every fixture has expectations');
}

# A long body: the preview stops at 256 characters.
{
  my $m = Data::JSEmail::parse("Subject: long\r\n\r\n" . ("word " x 200) . "\r\n");
  is(length($m->{preview}), 256, 'preview of a long body is 256 characters');
}

# S4.1.4 "type": in a multipart/digest the implicit type is message/rfc822.
{
  my $m = parse_fixture('digest.eml');
  local $TODO = 'implicit type is always text/plain, even in multipart/digest (bodystructure(), lib line 90-96)';
  is(leaf_by_id($m, '2.1')->{type}, 'message/rfc822', 'digest.eml: digest part defaults to message/rfc822');
  is_deeply(part_ids($m->{textBody}), ['1'], 'digest.eml: digest entries are not body text');
  is_deeply(part_ids($m->{attachments}), ['2.1', '2.2'], 'digest.eml: digest entries are attachments');
}

# A boundary that never appears: best effort, not a crash.
{
  my $m = eval { parse_fixture('bad-boundary.eml') };
  my $err = $@;
  ok($m, 'bad-boundary.eml: parses') or diag $err;
  is(ref($m && $m->{textBody}), 'ARRAY', 'bad-boundary.eml: has a textBody list');
  is($m->{subject}, 'Boundary never appears', 'bad-boundary.eml: the headers are still read');
  # The multipart cannot be split, so its content is kept whole as one
  # opaque leaf: a multipart type with no subParts is not allowed.
  is($m->{bodyStructure}{type}, 'application/octet-stream', 'bad-boundary.eml: unsplittable multipart is an opaque leaf');
  is($m->{bodyStructure}{partId}, '1', 'bad-boundary.eml: the leaf has a partId');
  is_deeply(part_ids($m->{attachments}), ['1'], 'bad-boundary.eml: and is an attachment');
  check_invariants('bad-boundary.eml', $m) if $m;
}

# Malformed MIME degrades the part it is in, not the message.
sub nested {
  my ($depth) = @_;
  return "Content-Type: text/plain\r\n\r\ndeep text\r\n" unless $depth;
  my $b = "b$depth";
  return "Content-Type: multipart/mixed; boundary=$b\r\n\r\n"
    . "--$b\r\nContent-Type: text/plain\r\n\r\nlevel $depth\r\n"
    . "--$b\r\n" . nested($depth - 1) . "--$b--\r\n";
}
{
  # Email::MIME dies on nesting deeper than $Email::MIME::MAX_DEPTH (10).
  my $raw = "From: a\@example.com\r\nSubject: deep\r\n" . nested(15);
  my $m = eval { Data::JSEmail::parse($raw, 'deep') };
  ok($m, 'deep nesting: parses') or diag $@;
  is($m && $m->{subject}, 'deep', 'deep nesting: headers read');
  is($m && value_of_id($m, q{1}), "level 15", 'deep nesting: the shallow parts are read');
  my @opaque = $m ? grep { $_->{type} eq 'application/octet-stream' } leaves($m->{bodyStructure}) : ();
  is(scalar @opaque, 1, 'deep nesting: only the part past the limit is opaque');
  check_invariants('deep nesting', $m) if $m;
}
{
  # ... and on a message of more than $Email::MIME::MAX_PARTS (100) parts.
  my $raw = "From: a\@example.com\r\nSubject: wide\r\nContent-Type: multipart/mixed; boundary=w\r\n\r\n"
    . join('', map { "--w\r\nContent-Type: text/plain\r\n\r\npart $_\r\n" } 1 .. 150) . "--w--\r\n";
  my $m = eval { Data::JSEmail::parse($raw, 'wide') };
  ok($m, 'too many parts: parses') or diag $@;
  is($m && $m->{subject}, 'wide', 'too many parts: headers read');
  like($m && $m->{bodyStructure}{size}, qr/^[1-9]/, 'too many parts: the content is kept');
}
sub value_of_id { my ($m, $id) = @_; my $v = $m->{bodyValues}{$id}; $v && $v->{value} }

is_deeply(\@warnings, [], 'no warnings');

done_testing;
