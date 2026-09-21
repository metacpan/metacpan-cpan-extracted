#!/usr/bin/env perl
# Does S3 accept the Content-Encoding order that this module sends?
#
#    ./10-s3-content-encoding-probe.pl BUCKET [KEY_PREFIX]
#
# With streaming, sign() has to add "aws-chunked" to whatever
# Content-Encoding the caller already set. RFC 9110 and botocore put it
# last ("gzip,aws-chunked"), because aws-chunked is applied to the
# already compressed data; the S3 documentation was read the other way
# round in an earlier review of this distribution. See TODO.md: nothing
# but a real bucket can settle it, and this is the program that asks.
#
# Two objects are uploaded: a control with no Content-Encoding of its
# own, and the real case with gzip. The control tells a wrong order apart
# from a wrong bucket, region or set of credentials. Both are deleted
# again, unless KEEP=1.
#
# The report at the end is meant to be pasted in a bug report or a chat:
# it is built from a fixed list of fields, so it carries no credentials,
# no Authorization header, no session token, and neither bucket nor key.
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use HTTP::Tiny;
use IO::Compress::Gzip qw< gzip $GzipError >;

my ($bucket, $prefix) = @ARGV;
# an empty bucket would also leave redact() with an empty pattern, which
# in Perl means "the last pattern that matched", i.e. no redaction at all
die "usage: $0 BUCKET [KEY_PREFIX]\n" unless defined $bucket && length $bucket;
$prefix = 'aws-sigv4-probe/' unless defined $prefix && length $prefix;
my $region = $ENV{AWS_REGION} // 'us-east-1';

# the bucket and the region are pasted into the host name below. A "/" in
# either of them moves the host somewhere else entirely -- "evil.com/x"
# makes the URL https://evil.com/x.s3... -- and the request would be
# signed and sent there, session token included. The prefix goes in the
# path, where a "?" or a "#" would change which object is addressed, and
# the DELETE at the end follows the same URL
die "invalid bucket name: it must be 3 to 63 letters, digits, dots or dashes\n"
   unless $bucket =~ m{\A[A-Za-z0-9][A-Za-z0-9.-]{1,61}[A-Za-z0-9]\z};
die "invalid region: it must be letters, digits and dashes\n"
   unless $region =~ m{\A[a-z0-9-]+\z};
die "invalid key prefix: use letters, digits, dot, dash, underscore, tilde and /\n"
   unless $prefix =~ m{\A[A-Za-z0-9._~/-]+\z};

my $signer = AWS::Signature::V4->new(
   service     => 's3',
   region      => $region,
   credentials => {
      access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
      secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
      session_token     => $ENV{AWS_SESSION_TOKEN},
   },
);

# something that compresses well, so that the gzipped payload is clearly
# not the plain one and a body that came back unzipped cannot be mistaken
# for a good round trip
my $plain = "the quick brown fox jumps over the lazy dog\n" x 100;
gzip \$plain, \my $gz or die "gzip failed: $GzipError\n";
my $chunk_size = 64 * 1024;    # one data chunk: the last one, so S3's
my $size       = length $gz;   # 8 KiB minimum does not apply to it
my $chunks     = int($size / $chunk_size) + ($size % $chunk_size ? 1 : 0);

my $http = HTTP::Tiny->new(verify_SSL => 1);
my $base = "https://$bucket.s3.$region.amazonaws.com/";

# HTTP::Tiny adds the Host header itself and refuses to be given one; it
# is signed all the same, and it will have the same value
sub without_host {
   my ($r) = @_;
   my %headers = $r->{headers}->%*;
   delete $headers{host};
   return \%headers;
}

# S3 reports failures as XML; the first two fields are the useful ones.
# HTTP::Tiny never reached it when the status is 599, and then the reason
# (no route, TLS refused, name not resolved) is in the content instead
sub s3_error {
   my ($response) = @_;
   my $content = $response->{content} // '';
   my ($code) = $content =~ m{<Code>([^<]*)</Code>};
   my ($msg)  = $content =~ m{<Message>([^<]*)</Message>};
   return one_line(defined $msg && length $msg ? "$code: $msg" : $code) if defined $code;
   return '' unless ($response->{status} // 0) == 599;
   return one_line($content);
}

# the S3 error code on its own (NoSuchBucket, AccessDenied, ...). Its
# presence is what tells a refusal by S3 apart from a failure that never
# reached it, which is the difference between an answer and a bad run
sub s3_code {
   my ($response) = @_;
   my ($code) = ($response->{content} // '') =~ m{<Code>([^<]*)</Code>};
   return undef unless defined $code && length $code;
   return one_line($code);
}

# the status line comes from the other end as well: HTTP::Tiny takes the
# reason as [^\r\n]*, so it can carry control characters, terminal escapes
# and any length at all, and it goes in the report like everything else
sub status_of {
   my ($response) = @_;
   return one_line(($response->{status} // 0) . ' ' . ($response->{reason} // ''));
}

# every word of this is written by the other end of the connection, and it
# is quoted in a report that gets read as evidence: keep it to one bounded
# line of printable ASCII, so that it cannot forge a line of that report
# (a <Message> holding a newline and "verdict: ..." otherwise would)
sub one_line {
   my ($text) = @_;
   return '' unless defined $text && length $text;
   $text =~ s{\s+}{ }g;
   $text =~ s{[^\x20-\x7E]}{.}g;
   $text =~ s{\A\s+}{};
   $text =~ s{\s+\z}{};
   $text = substr($text, 0, 197) . '...' if length $text > 200;
   return redact($text);
}

# both kinds of error quote the URL or the key back at us, and the report
# is meant to be pasted: keep the bucket and the key out of it
sub redact {
   my ($text) = @_;
   return $text unless defined $text && length $text;
   $text =~ s{\Q$bucket\E}{BUCKET}g;
   $text =~ s{\Q$prefix\E}{KEY-PREFIX/}g;
   return $text;
}

# HTTP::Tiny lowercases header names and gives an array reference when a
# header appears more than once
sub header_of {
   my ($response, $name) = @_;
   my $v = $response->{headers}{$name};
   return '(none)' unless defined $v;
   # also written by the other end, so it goes through the same sieve
   return one_line(ref $v eq 'ARRAY' ? join(',', $v->@*) : $v);
}

my @cases = (
   {name => 'A control', key => $prefix . 'control', extra => {}},
   {name => 'B gzip',    key => $prefix . 'gzip',    extra => {'Content-Encoding' => 'gzip'}},
);

# undef when the key can be used, otherwise why it cannot. This program
# deletes what it uploads, so it must only ever touch keys that hold
# nothing: anything short of a clear "not there" is taken as occupied
sub key_in_the_way {
   my ($key) = @_;
   my $url = $base . $key;
   my $r = $signer->sign(method => 'HEAD', url => $url);
   my $head = $http->request(HEAD => $url, {headers => without_host($r)});
   return undef if ($head->{status} // 0) == 404;
   return 'an object is already there' if $head->{success};
   # without s3:ListBucket, S3 answers HEAD on a key that is not there
   # with 403 rather than 404, so a free key cannot be told from a
   # forbidden one -- and Get/Put/DeleteObject alone, which is all this
   # program needs, is exactly the case where that happens
   return 'cannot tell whether it is free: S3 said 403, which without '
      . 's3:ListBucket is also the answer for a key that does not exist'
      if ($head->{status} // 0) == 403;
   return 'cannot tell whether it is free (' . status_of($head) . ')';
}

if (!$ENV{DRY_RUN}) {
   for my $c (@cases) {
      my $why = key_in_the_way($c->{key}) // next;
      die "refusing to use the key '$c->{key}': $why.\n",
          "This program overwrites and then deletes the keys it uses, so it\n",
          "only touches ones that hold nothing. If that key is in fact free,\n",
          "then the check itself failed: verify the bucket, the region and\n",
          "the credentials, and grant s3:ListBucket on the bucket so that a\n",
          "missing key answers 404 instead of 403. Otherwise pass a\n",
          "KEY_PREFIX that points at empty space, e.g.:\n",
          "   $0 $bucket probe-", time, "/\n";
   }
}

for my $c (@cases) {
   my $url = $base . $c->{key};
   my $r = $signer->sign(
      method  => 'PUT',
      url     => $url,
      headers => {
         $c->{extra}->%*,
         'Content-Type' => 'text/plain',
         # length of the *encoded* body: data plus the chunk framing
         'Content-Length' => AWS::Signature::V4->encoded_length($size, $chunk_size),
      },
      streaming              => 1,
      decoded_content_length => $size,
   );
   # what the module decided to send, rather than what we assume it sends:
   # this is the whole question, and it must be reported as it is
   $c->{sent}     = $r->{headers}{'content-encoding'};
   $c->{announced} = $r->{headers}{'content-length'};
   # the encoded body is built once, whole, and sent as a string. A
   # callback would be the thing to do for a real upload (example 05 does
   # that), but HTTP::Tiny retries an idempotent request once when the
   # socket breaks under it, and this body cannot be produced a second
   # time: the chunk signatures chain, and finish() has already been
   # called, so the retry would send nothing and fail on the length --
   # reported as a 599, which reads like a refusal and is not one. A few
   # hundred bytes in memory buy a run that means what it says
   my $chunker = $r->{chunker};
   my $body    = '';
   for (my $offset = 0; $offset < $size; $offset += $chunk_size) {
      $body .= $chunker->chunk(substr $gz, $offset, $chunk_size);
   }
   $body .= $chunker->finish;    # last, empty chunk (dies if sizes disagree)

   if ($ENV{DRY_RUN}) {
      $c->{dry} = sprintf 'body %d bytes, announced %d', length $body, $c->{announced};
      next;
   }

   my $put = $http->request(PUT => $url,
      {headers => without_host($r), content => $body});
   $c->{put}    = status_of($put);
   $c->{status} = $put->{status} // 0;
   if (!$put->{success}) {
      $c->{put_error} = s3_error($put);
      $c->{s3_code}   = s3_code($put);
      next;
   }
   $c->{ok} = 1;

   my $g = $signer->sign(method => 'GET', url => $url);
   my $get = $http->get($url, {headers => without_host($g)});
   $c->{get} = status_of($get);
   if ($get->{success}) {
      $c->{stored} = header_of($get, 'content-encoding');
      my $got = $get->{content} // '';
      $c->{body} =
           $got eq $gz    ? 'identical'
         : $got eq $plain ? 'DECOMPRESSED on the way (S3 or the client unzipped it)'
         : sprintf('DIFFERENT (%d bytes back, %d sent)', length $got, $size);
   }
   else { $c->{get_error} = s3_error($get) }

   next if $ENV{KEEP};
   my $d = $signer->sign(method => 'DELETE', url => $url);
   my $del = $http->request(DELETE => $url, {headers => without_host($d)});
   $c->{leftover} = $c->{key} unless $del->{success};
}

# --- the report, safe to paste anywhere ------------------------------------
my @out = (
   '--- aws-chunked ordering probe ------------------------',
   "module:   AWS::Signature::V4 " . (AWS::Signature::V4->VERSION // '(unknown)'),
   "region:   $region          (bucket and key not shown)",
   sprintf('payload:  %d bytes plain -> %d bytes gzip, %d data chunk%s',
      length $plain, $size, $chunks, $chunks == 1 ? '' : 's'),
   '',
);
for my $c (@cases) {
   push @out, sprintf('%-10s sent   Content-Encoding: %s', $c->{name}, $c->{sent});
   push @out, "           dry    $c->{dry}" if defined $c->{dry};
   push @out, "           PUT    $c->{put}" if defined $c->{put};
   push @out, "           error  $c->{put_error}"
      if defined $c->{put_error} && length $c->{put_error};
   push @out, "           GET    $c->{get}" . (defined $c->{stored}
      ? "   stored Content-Encoding: $c->{stored}" : '') if defined $c->{get};
   push @out, "           error  $c->{get_error}"
      if defined $c->{get_error} && length $c->{get_error};
   push @out, "           body   $c->{body}" if defined $c->{body};
   push @out, '';
}

my ($control, $gzip_case) = @cases;

# a 200 is not the answer on its own. The question is what S3 made of the
# list, and the run already went and collected that: the Content-Encoding
# it kept, and whether the bytes came back as they were sent
my $confirmed = $gzip_case->{ok}
   && lc($gzip_case->{stored} // '') eq 'gzip'
   && ($gzip_case->{body} // '') eq 'identical';

# and a failure is only an answer when S3 itself refused the request. The
# control having gone through says nothing about the one after it: a 503
# SlowDown, a 500, a dropped connection or a key that expired in between
# would otherwise be read as a verdict on the order, and this report
# would send someone to change the signing code over a bad afternoon
my $put_status = $gzip_case->{status} // 0;    # unset in a dry run, and
                                               # if the preflight stopped
my $refused = !$gzip_case->{ok}
   && $put_status >= 400 && $put_status < 500
   # 401 and 403 are answers about the credentials, not about the header:
   # a key that expired between the control and this upload would land
   # here, and it is not the ordering that was turned down
   && $put_status != 401 && $put_status != 403
   && defined $gzip_case->{s3_code};

my $status = 0;
if ($ENV{DRY_RUN}) {
   push @out, 'verdict:  nothing was sent (DRY_RUN): the announced length';
   push @out, '          must equal the body size in both cases above';
}
elsif (!$control->{ok}) {
   push @out, 'verdict:  INCONCLUSIVE. The control upload failed, so this run';
   push @out, '          says nothing about the ordering: check the bucket, the';
   push @out, '          region and the credentials, then run it again.';
   $status = 1;
}
elsif ($confirmed) {
   push @out, "verdict:  S3 accepted $gzip_case->{sent}, stored it as";
   push @out, "          Content-Encoding: $gzip_case->{stored}, and gave the";
   push @out, '          bytes back unchanged.';
}
elsif ($gzip_case->{ok}) {
   push @out, "verdict:  INCONCLUSIVE. S3 took $gzip_case->{sent}, but what it";
   push @out, '          stored is not what this probe expects: read the stored';
   push @out, '          Content-Encoding and the body line above, because the';
   push @out, '          upload being accepted is then not the whole story.';
   $status = 1;
}
elsif ($refused) {
   push @out, "verdict:  S3 REJECTED $gzip_case->{sent} with $gzip_case->{s3_code},";
   push @out, "          while accepting $control->{sent} alone, so the order is";
   push @out, '          the problem. Swap the last line of the $streaming';
   push @out, '          branch in lib/AWS/Signature/V4.pm to';
   push @out, q{             join ',', 'aws-chunked', @encodings;};
   push @out, '          update V4.pod and t/streaming.t to match, and run';
   push @out, '          this program again to confirm the other order.';
   $status = 1;
}
else {
   push @out, 'verdict:  INCONCLUSIVE. The gzip upload failed, but not with a';
   push @out, '          refusal from S3, so it says nothing about the order:';
   push @out, '          see the error line above, then run it again.';
   $status = 1;
}
# the keys themselves go on stderr, outside the block that gets pasted
my @leftover = grep { defined } map { $_->{leftover} } @cases;
if (@leftover) {
   push @out, '', sprintf 'note:     %d object%s left behind, delete %s by hand',
      scalar @leftover, @leftover == 1 ? '' : 's', @leftover == 1 ? 'it' : 'them';
   warn "could not delete: $_\n" for @leftover;
}
push @out, '-------------------------------------------------------';
say for @out;
exit $status;
