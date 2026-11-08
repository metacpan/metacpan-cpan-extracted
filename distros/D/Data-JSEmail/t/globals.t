#!/usr/bin/perl

# Data::JSEmail runs with the Email::MIME package globals it was written
# against, whatever the caller has set them to: parse and make give the
# same answer under the caller's STRICT_PARAMS, PRE_2231_FORM and GROUCHY
# either way.  (The whole suite can also be run in strict mode:
# JSEMAIL_STRICT_PARAMS=1 prove -l t/.)

use strict;
use warnings;
use utf8;
use Test::More;

use lib 'lib', 't/lib';
use JSEmailTest qw(fixture blob_store);
use Data::JSEmail;
use Email::MIME::ContentType;
use Email::Simple;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

sub under {
  my ($strict, $pre2231, $code) = @_;
  local $Email::MIME::ContentType::STRICT_PARAMS = $strict;
  local $Email::MIME::ContentType::PRE_2231_FORM = $pre2231;
  local $Email::Simple::GROUCHY = $strict;
  return $code->();
}

opendir my $dh, 't/data' or die $!;
my @files = sort grep { /\.eml$/ } readdir $dh;

for my $file (@files) {
  my $raw = fixture($file);
  my $lax    = under(0, 1, sub { eval { Data::JSEmail::parse($raw, 'x') } // "died: $@" });
  my $strict = under(1, 0, sub { eval { Data::JSEmail::parse($raw, 'x') } // "died: $@" });
  is_deeply($strict, $lax, "$file: parse ignores the caller's Email::MIME settings");
}

# Parameters only the lax parser reads: an unquoted name with a space, a
# stray semicolon.
my $sloppy = join "\r\n",
  'From: a@example.com',
  'Content-Type: multipart/mixed; boundary=b',
  '', '--b',
  'Content-Type: text/plain; charset=utf-8;',
  '', 'body', '--b',
  'Content-Type: application/pdf; name=my file.pdf',
  'Content-Disposition: attachment; filename=my file.pdf;',
  'Content-Transfer-Encoding: base64',
  '', 'JVBERg==', '--b--', '';
for my $strict (0, 1) {
  my $m = under($strict, 1, sub { Data::JSEmail::parse($sloppy, 's') });
  is($m->{attachments}[0]{name}, 'my file.pdf', "sloppy parameters read with STRICT_PARAMS=$strict");
  is($m->{textBody}[0]{charset}, 'utf-8', "trailing semicolon tolerated with STRICT_PARAMS=$strict");
}

my $getblob = blob_store(pdf => [ 'application/pdf', "%PDF-1.4\n" ]);
my $create = {
  from        => [ { name => 'A', email => 'a@example.com' } ],
  subject     => 'Grüße',
  'header:Date'       => 'Sat, 07 Nov 2026 10:00:00 +0000',
  'header:Message-ID' => '<g@example.com>',
  bodyValues  => { 1 => { value => "x\n" } },
  textBody    => [ { partId => 1 } ],
  attachments => [ { blobId => 'pdf', type => 'application/pdf', name => 'Résumé, final "v2".pdf' } ],
};
my $mk = sub { my $raw = Data::JSEmail::make({ %$create }, $getblob); $raw =~ s/boundary="?[^";\r\n]+"?/boundary=B/g; $raw =~ s/^--\S+/--B/mg; $raw };
my $lax = under(0, 1, $mk);
is(under(1, 0, $mk), $lax, "make ignores the caller's Email::MIME settings");

is_deeply(\@warnings, [], 'no warnings');

done_testing;
