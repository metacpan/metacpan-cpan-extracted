#!/usr/bin/perl -cw

use strict;
use warnings;

package Data::JSEmail;

our $VERSION = '0.07';

use JSON;
use JSON::XS;
use HTML::Strip;
use Email::MIME;
use Email::MIME::ContentType;
use Email::Address::XS;
use Encode;
use Encode::MIME::Header;
use Unicode::Normalize;
use Date::Format;
use Date::Parse;
use DateTime;
use DateTime::Format::Mail;
use DateTime::Format::ISO8601::Format;

use Digest::SHA;
use Data::UUID;
use Sys::Hostname;

my $json = JSON::XS->new->utf8->canonical();

# The Email::MIME settings this module is written against.  They are
# package globals, so a caller may have set them either way for its own
# reasons; every entry point runs with these values instead, so what this
# module returns does not depend on who calls it.
#   STRICT_PARAMS = 0: accept the unquoted and otherwise sloppy
#     Content-Type/Content-Disposition parameters real mail is full of
#     (strict mode drops them, or the whole header, with a warning).
#   PRE_2231_FORM = 1: write a plain name=/filename= next to an RFC 2231
#     one, for readers that do not know RFC 2231.
#   GROUCHY = 0: do not die on a message without a header/body separator.
sub _with_settings {
  my $code = shift;
  local $Email::MIME::ContentType::STRICT_PARAMS = 0;
  local $Email::MIME::ContentType::PRE_2231_FORM = 1;
  local $Email::Simple::GROUCHY = 0;
  return $code->(@_);
}

sub parse { _with_settings(\&_parse, @_) }

sub _parse {
  my $rfc822 = shift;
  my $id = shift || Digest::SHA::sha256_hex($rfc822);
  my $eml = Data::JSEmail::MIMEPart->new($rfc822);
  my $res = _parse_email($id, $eml);
  $res->{size} = length($rfc822);
  return $res;
}

sub parse_email { _with_settings(\&_parse_email, @_) }

sub _parse_email {
  my $id = shift;
  my $eml = shift;
  my $part = shift;

  my $preview = preview($eml);
  my $headers = headers($eml);

  my %values;
  my $bodystructure = bodystructure(\%values, $id, $eml);
  my $textBody = [];
  my $htmlBody = [];
  my $attachments = [];
  parseStructure([$bodystructure], 'mixed', 0, $textBody, $htmlBody, $attachments);

  my ($hasAtt) = grep { ($_->{disposition} // '') ne 'inline' } @$attachments;

  # S4.1.3: each convenience property is its header:{name}:as{form}, so
  # it is computed from the same Raw values (Email::MIME's header() has
  # already decoded them, and returns the first instance, not the last).
  my %raw;
  push @{ $raw{ lc $_->{name} } }, $_->{value} for @$headers;
  my $hv = sub { my ($form, $name) = @_; header_value($form, $raw{ lc $name } || []) };
  my $data = {
    id => $id,
    sender => $hv->(asAddresses => 'Sender'),
    to => $hv->(asAddresses => 'To'),
    cc => $hv->(asAddresses => 'Cc'),
    bcc => $hv->(asAddresses => 'Bcc'),
    from => $hv->(asAddresses => 'From'),
    replyTo => $hv->(asAddresses => 'Reply-To'),
    subject => $hv->(asText => 'Subject'),
    sentAt => $hv->(asDate => 'Date'),
    messageId => $hv->(asMessageIds => 'Message-Id'),
    references => $hv->(asMessageIds => 'References'),
    inReplyTo => $hv->(asMessageIds => 'In-Reply-To'),
    preview => $preview,
    hasAttachment => $hasAtt ? $JSON::true : $JSON::false,
    headers => $headers,
    bodyStructure => $bodystructure,
    bodyValues => \%values,
    textBody => $textBody,
    htmlBody => $htmlBody,
    attachments => $attachments,
  };

  return $data;
}

sub bodystructure {
  my $values = shift;
  my $id = shift;
  my $eml = shift;
  my $partno = shift;

  my $type = {
    'subtype' => 'plain',
    'type' => 'text'
  };
  if (my $val = $eml->header('Content-Type')) {
    $type = parse_content_type($val);
  }
  my @parts = $eml->subparts();
  if (@parts) {
    my @sub;
    for (my $n = 1; $n <= @parts; $n++) {
      my $subno = $partno ? "$partno.$n" : $n;
      # One part that cannot be read must not cost the reader the rest
      # of the message: it becomes an opaque leaf.
      my $node = eval { bodystructure($values, $id, $parts[$n-1], $subno) };
      $node //= _opaque_leaf($id, $parts[$n-1], $subno);
      push @sub, $node;
    }
    return {
      partId => undef,
      blobId => undef,
      type => "$type->{type}/$type->{subtype}",
      size => 0,
      headers => headers($eml),
      name => undef,
      cid => asOneURL($eml->header('Content-Id')),
      charset => $type->{attributes}{charset},
      language => asCommaList($eml->header('Content-Language')),
      location => undef,
      disposition => undef,
      subParts => \@sub,
    };
  }
  else {
    my $disposition = {};
    if (my $val = $eml->header('Content-Disposition')) {
      my $orig = $val;
      $val =~ s{^(.*filename=\s*)([^\s"][^;]+)}{$1"$2"};
      $disposition = parse_content_disposition($val);
    }
    $partno ||= '1';
    # A multipart that yielded no parts (its boundary never appears, or
    # it is nested or split past Email::MIME's limits) is kept whole as
    # one opaque leaf: a part with a multipart type must have subParts
    # (RFC 8621 S4.1.4), and this one's content cannot be split into any.
    $type = { type => 'application', subtype => 'octet-stream', attributes => {} }
      if lc $type->{type} eq 'multipart';
    my $body = $eml->body();
    my $raw_size = length($body); # size in octets of decoded content
    if ($type->{type} eq 'text') {
      # Decode charset to Perl character string
      my $decoded = eval { $eml->body_str() };
      if (defined $decoded) {
        $body = $decoded;
      } else {
        # Fallback: try UTF-8 decode
        $body = eval { Encode::decode('UTF-8', $body) } // $body;
      }
      # RFC 8621: line endings in bodyValues MUST be \n not \r\n
      my $text_body = $body;
      $text_body =~ s/\r\n/\n/g;
      # RFC 8621 S4.1.4: isEncodingProblem is also true when the
      # content-transfer-encoding was unknown.  Email::MIME::body()
      # quietly treats an unknown one as 7bit, so check it ourselves;
      # the value stays the best-effort (undecoded) body.
      my $problem = !defined($decoded) || !_known_cte($eml);
      $values->{$partno} = {
        value => $text_body,
        isEncodingProblem => ($problem ? $JSON::true : $JSON::false),
        isTruncated => $JSON::false,
      };
    }
    my $charset = $type->{attributes}{charset};
    if ($type->{type} eq 'text' and not $charset) {
      $charset = 'us-ascii';
    }
    return {
      partId => "$partno",
      blobId => "m-$id-$partno",
      type => "$type->{type}/$type->{subtype}",
      size => $raw_size,
      headers => headers($eml),
      name => $disposition->{attributes}{filename} // $type->{attributes}{name},
      cid => asOneURL($eml->header('Content-Id')),
      charset => $charset,
      language => asCommaList($eml->header('Content-Language')),
      location => asText($eml->header('Content-Location')),
      disposition => $disposition->{type},
    };
  }
}

# The leaf a part that could not be read at all is reported as.
sub _opaque_leaf {
  my ($id, $eml, $partno) = @_;
  my $raw = eval { $eml->body_raw } // '';
  return {
    partId => "$partno",
    blobId => "m-$id-$partno",
    type => 'application/octet-stream',
    size => length($raw),
    headers => (eval { headers($eml) } || []),
    name => undef,
    cid => undef,
    charset => undef,
    language => undef,
    location => undef,
    disposition => undef,
  };
}

sub asDate {
  my $val = shift;
  return undef unless defined $val;
  $val =~ s/\(.*//;  # strip comments
  $val =~ s/^\s+//;  # strip leading whitespace
  $val =~ s/\s+\z//;  # strip trailing whitespace
  # Add :00 seconds if missing (e.g. "23:32 -0330" → "23:32:00 -0330")
  $val =~ s/(\s\d{2}:\d{2})\s+([-+]\d{4})/$1:00 $2/;
  my $dt = eval { DateTime::Format::Mail->parse_datetime($val) };
  return undef unless $dt;
  my $tz = $dt->time_zone;
  if ($tz->isa('DateTime::TimeZone::Floating')) {
    $dt->set_time_zone('UTC');
  }
  return DateTime::Format::ISO8601::Format->new->format_datetime($dt);
}

sub asMessageIds {
  my $val = shift;
  return undef unless $val;
  my @list = $val =~ m{<([^\>]+)>}gs;
  return undef unless @list;
  return \@list;
}

sub asCommaList {
  my $val = shift;
  return undef unless defined $val;
  $val =~ s/^\s+//;
  $val =~ s/\s+\z//;
  my @list = split /\s*,\s*/, $val;
  return \@list;
}

sub asURLs {
  my $val = shift;
  return undef unless defined $val;
  $val =~ s/^\s+//;
  $val =~ s/\s+\z//;
  return undef unless length($val);

  # Extract URLs from angle brackets
  my @list;
  while ($val =~ m/<([^>]+)>/gs) {
    push @list, $1;
  }
  return \@list if @list;

  # No angle brackets — treat whole value as a URL if it looks like one
  return undef unless $val =~ m{^[a-zA-Z][a-zA-Z0-9+.-]*:};
  $val =~ s/ .*//; # strip after first whitespace
  return [$val];
}

sub asOneURL {
  my $val = shift;
  my $list = asURLs($val) || [];
  return $list->[-1];
}

sub asText {
  my $val = shift;
  return undef unless defined $val;
  # Decode MIME-Header encoded words, then NFC normalize
  my $decoded = eval { decode('MIME-Header', $val) };
  $decoded = $val unless defined $decoded;
  # If still raw bytes (not flagged as UTF-8), try UTF-8 decode
  if (!Encode::is_utf8($decoded) && $decoded =~ /[\x80-\xff]/) {
    $decoded = eval { Encode::decode('UTF-8', $decoded) } // $decoded;
  }
  my $res = NFC($decoded);
  $res =~ s/^\s*//;
  # \s+\z, not \s*$: the regex engine tried every position of a long run
  # of spaces inside the value, so "a<80000 spaces>b" took seconds
  $res =~ s/\s+\z//;
  return $res;
}

# An addr-spec as JMAP reports it: RFC 6532 lets the local part and domain
# be UTF-8, which arrives as octets and must become characters (or it is
# encoded a second time on output); the domain is lower-cased. Octets that
# are not UTF-8 are left as they are.
sub _addr_spec {
  my ($email) = @_;
  return $email unless defined $email;
  if ($email =~ /[\x80-\xff]/ && $email !~ /[^\x00-\xff]/) {
    my $copy = $email;
    my $chars = eval { Encode::decode('UTF-8', $copy, Encode::FB_CROAK) };
    $email = NFC($chars) if defined $chars;
  }
  $email =~ s/\@(.*)/"@" . lc($1)/e;
  return $email;
}

# The (group, [mailbox...]) pairs of an address-list Raw value, with the
# phrases still encoded: asText decodes them, once.  (Email::MIME's
# from_mime_string decodes them first, so they were decoded twice.)
sub _address_groups {
  my $raw = shift;
  my @groups = eval { Email::Address::XS::parse_email_groups($raw) };
  return $@ ? undef : \@groups;
}

sub asAddresses {
  my $emails = shift;

  my $res = asGroupAddresses($emails);
  return undef unless $res;

  my $arr = [ grep { defined $_->{email} } @$res ];
  return $arr;
}

sub asGroupedAddresses {
  # RFC 8621: returns EmailAddressGroup[] — [{name, addresses}]
  my $emails = shift;
  return undef unless defined $emails;
  my $groups = _address_groups($emails) or return undef;
  my @addrs = @$groups;
  my @res;
  while (@addrs) {
    my $group = shift @addrs;
    my $list = shift @addrs;
    my @addresses;
    foreach my $addr (@$list) {
      my $name = $addr->phrase();
      my $email = _addr_spec($addr->address());
      push @addresses, {
        name => asText($name),
        email => $email,
      };
    }
    push @res, {
      name => defined $group ? asText($group) : undef,
      addresses => \@addresses,
    };
  }
  return \@res;
}

sub asGroupAddresses {
  # Internal format with sentinel entries (backward compat)
  my $emails = shift;

  return undef unless defined $emails;
  my $groups = _address_groups($emails) or return undef;
  my @addrs = @$groups;
  my @res;
  while (@addrs) {
    my $group = shift @addrs;
    my $list = shift @addrs;
    if (defined $group) {
      push @res, {
        name => asText($group),
        email => undef,
      };
    }
    foreach my $addr (@$list) {
      my $name = $addr->phrase();
      my $email = _addr_spec($addr->address());
      push @res, {
        name => asText($name),
        email => $email,
      };
    }
    if (defined $group) {
      push @res, {
        name => undef,
        email => undef,
      };
    }
  }

  return \@res;
}

sub headers {
  my $eml = shift;
  # Parse raw header string to preserve exact values including
  # leading whitespace after colon (RFC 8621 raw header form)
  my $raw = $eml->header_obj->as_string;
  my @res;
  # Unfold continuation lines first, then split on header boundaries
  my @lines;
  for my $line (split /\r?\n/, $raw) {
    if ($line =~ /^\s/ && @lines) {
      # Continuation line — append to previous
      $lines[-1] .= "\r\n$line";
    }
    elsif ($line =~ /^([^:]+):(.*)/) {
      push @lines, $line;
    }
  }
  for my $line (@lines) {
    if ($line =~ /^([^:]+):(.*)$/s) {
      push @res, { name => $1, value => $2 };
    }
  }
  return \@res;
}

# The content-transfer-encodings RFC 2045 S6.1 defines; anything else
# (an x-token, a typo) is one we cannot decode.
my %KNOWN_CTE = map { $_ => 1 } qw(7bit 8bit binary base64 quoted-printable);

# True if the part has no Content-Transfer-Encoding or one we know.
sub _known_cte {
  my $eml = shift;
  my $cte = $eml->header('Content-Transfer-Encoding');
  return 1 unless defined $cte;
  $cte =~ s/;.*//s;           # drop any parameters (S/MIME etc.)
  $cte =~ s/\A\s+|\s+\z//g;
  return 1 if $cte eq '';
  return $KNOWN_CTE{lc $cte} ? 1 : 0;
}

sub _clean {
  my ($type, $text) = @_;
  return $text;
}

sub _body_str {
  my $eml = shift;
  my $str = eval { $eml->body_str() };
  return $str if $str;
  return Encode::decode('us-ascii', $eml->body_raw());
}

# XXX: re-define on top of bodyStructure?
sub preview {
  my $eml = shift;
  my $type = $eml->content_type() || 'text/plain';
  if ($type =~ m{text/plain}i) {
    my $text = _clean($type, _body_str($eml));
    return make_preview($text);
  }
  if ($type =~ m{text/html}i) {
    my $text = _clean($type, _body_str($eml));
    return make_preview(_html_preview_text($text));
  }
  foreach my $sub ($eml->subparts()) {
    my $res = eval { preview($sub) };
    return $res if $res;
  }
  return undef;
}

# The first 256 characters of $text with each run of whitespace made one
# space.  Collapsing a prefix of the text gives a prefix of the collapsed
# whole (a run cut short still becomes one space), so only as much of a
# long body is looked at as it takes to fill the preview: collapsing all of
# a megabyte body to keep 256 characters was most of what parsing it cost.
sub make_preview {
  my $text = shift // '';
  my $len = 1024;
  while (1) {
    my $part = length($text) > $len ? substr($text, 0, $len) : $text;
    (my $c = $part) =~ s/\s+/ /gs;
    return substr($c, 0, 256) if length($c) >= 256 || length($part) == length($text);
    $len *= 4;
  }
}

# The text of an HTML body, as htmltotext gives it, but only enough of it
# for a preview: HTML::Strip keeps its state between calls, so it is fed
# pieces ending just after a '>' (never inside a tag or an entity) until
# 256 characters of text have come out.
sub _html_preview_text {
  my $html = shift // '';
  my $hs = HTML::Strip->new();
  my ($out, $pos, $chunk) = ('', 0, 8192);
  while ($pos < length $html) {
    my $end = $pos + $chunk;
    if ($end < length $html) {
      my $gt = rindex($html, '>', $end);
      $end = $gt + 1 if $gt >= $pos;
    }
    $out .= $hs->parse(substr($html, $pos, $end - $pos));
    $pos = $end;
    (my $c = $out) =~ s/\s+/ /gs;
    return $out if length($c) > 256 && $pos < length $html;
    $chunk *= 2;
  }
  $out .= $hs->eof // '';
  return $out;
}

sub hasatt {
  my $bs = shift;
  if ($bs->{subParts}) {
    foreach my $sub (@{$bs->{subParts}}) {
      return 1 if hasatt($sub);
    }
  }
  return 1 if $bs->{type} =~ m{(image|video|application)/};  # others?
  return 0;
}

sub isInlineMediaType {
  my $type = shift;
  return 1 if $type =~ m{^image/};
  return 1 if $type =~ m{^audio/};
  return 1 if $type =~ m{^video/};
  return 0;
}

sub parseStructure {
  my $parts = shift;
  my $multipartType = shift;
  my $inAlternative = shift;
  my $textBody = shift;
  my $htmlBody = shift;
  my $attachments = shift;

  my $textCount = $textBody ? scalar @$textBody : -1;
  my $htmlCount = $htmlBody ? scalar @$htmlBody : -1;

  for (my $i = 0; $i < @$parts; $i++) {
    my $part = $parts->[$i];
    my $isMultipart = $part->{subParts} ? 1 : 0;
    my $subMultiType = $isMultipart && $part->{type} =~ m{^multipart/(.*)}i ? lc $1 : '';

    # Determine part type (matching Cyrus classification)
    my $isPlain = $part->{type} eq 'text/plain'
               || $part->{type} eq 'text/richtext'
               || $part->{type} eq 'text/enriched';
    my $isHTML = $part->{type} eq 'text/html';
    my $isInlineMedia = isInlineMediaType($part->{type});

    my $isInline = ($part->{disposition} // '') ne 'attachment' &&
        ($isPlain || $isHTML || $isInlineMedia) &&
        ($i == 0 ||
            ( $multipartType ne 'related' &&
                ( $isInlineMedia || !$part->{name} ) ) );

    if ($isMultipart) {
      parseStructure($part->{subParts}, $subMultiType,
          $inAlternative || ( $subMultiType eq 'alternative' ),
          $textBody, $htmlBody, $attachments);
    }
    elsif ($isInline) {
      if ($multipartType eq 'alternative') {
        if ($isPlain && $textBody) {
          push @$textBody, $part;
        }
        elsif ($isHTML && $htmlBody) {
          push @$htmlBody, $part;
        }
        else {
          push @$attachments, $part;
        }
        next;
      }
      # Inside an alternative ancestor: seeing a text part means
      # we can't also use it for HTML, and vice versa
      if ($inAlternative) {
        if ($isPlain) {
          $htmlBody = undef;
        }
        elsif ($isHTML) {
          $textBody = undef;
        }
      }
      push @$textBody, $part if $textBody;
      push @$htmlBody, $part if $htmlBody;
      if ((!$textBody || !$htmlBody) && $isInlineMedia) {
        push @$attachments, $part;
      }
    }
    else {
      push @$attachments, $part;
    }
  }

  # Alternative fallback: if only one type was found, copy to the other
  if ($multipartType eq 'alternative' && $textBody && $htmlBody) {
    if ($textCount == scalar @$textBody) {
      # No text parts found, copy HTML parts to text
      push @$textBody, @{$htmlBody}[$htmlCount .. $#$htmlBody];
    }
    if ($htmlCount == scalar @$htmlBody) {
      # No HTML parts found, copy text parts to HTML
      push @$htmlBody, @{$textBody}[$textCount .. $#$textBody];
    }
  }
}

# --- header forms (RFC 8621 S4.1.2, S4.1.3) --------------------------------
#
# One codec for the parsed header forms, used in both directions: the
# get side (header_value) reads the Raw value of each instance, and the
# create side (format_header) writes a Raw value that header_value reads
# back as what was given.  make() and parse() use these for every header
# they read or write, the convenience properties included.

my %GET_FORM = (
  asRaw              => sub { $_[0] },
  asText             => \&asText,
  asAddresses        => \&asAddresses,
  asGroupedAddresses => \&asGroupedAddresses,
  asMessageIds       => \&asMessageIds,
  asDate             => \&asDate,
  asURLs             => \&asURLs,
);

sub _form_name {
  my $form = shift;
  return 'asRaw' if !defined $form || $form eq '' || $form eq 'Raw';
  return $form;
}

sub header_value {
  my ($form, $raw_values, %opt) = @_;
  $form = _form_name($form);
  my $conv = $GET_FORM{$form} or die "Unknown header form '$form'\n";
  my @values = grep { defined } (ref $raw_values eq 'ARRAY' ? @$raw_values : ($raw_values));
  return [ map { $conv->($_) } @values ] if $opt{all};
  return @values ? $conv->($values[-1]) : undef;
}

sub header_property {
  my ($headers, $prop) = @_;
  my ($name, $form, $all) = parse_header_property($prop)
    or die "Invalid header property '$prop'\n";
  my @values = map { $_->{value} }
               grep { lc($_->{name} // '') eq lc $name } @{ $headers || [] };
  return header_value($form, \@values, all => $all);
}

sub parse_header_property {
  my $prop = shift;
  return () unless defined $prop
    && $prop =~ /\Aheader:([\x21-\x39\x3b-\x7e]+?)(?::(as[A-Za-z]+))?(:all)?\z/;
  my ($name, $form, $all) = ($1, _form_name($2), $3 ? 1 : 0);
  return () unless $GET_FORM{$form};
  return ($name, $form, $all);
}

# RFC 8621 S4.1.2: the header fields each parsed form may be used on.
# A field not defined in RFC 5322 or RFC 2369 may use every form.
my %FORM_FIELDS = (
  asText       => [qw(subject comments keywords list-id)],
  asAddresses  => [qw(from sender reply-to to cc bcc resent-from resent-sender
                      resent-reply-to resent-to resent-cc resent-bcc)],
  asMessageIds => [qw(message-id in-reply-to references resent-message-id)],
  asDate       => [qw(date resent-date)],
  asURLs       => [qw(list-help list-unsubscribe list-subscribe list-post
                      list-owner list-archive)],
);
$FORM_FIELDS{asGroupedAddresses} = $FORM_FIELDS{asAddresses};
my %FORM_ALLOWED = map { my $f = $_; ($f => { map { $_ => 1 } @{ $FORM_FIELDS{$f} } }) } keys %FORM_FIELDS;
my %DEFINED_FIELD = map { $_ => 1 } qw(
  date from sender reply-to to cc bcc message-id in-reply-to references subject
  comments keywords resent-date resent-from resent-sender resent-to resent-cc
  resent-bcc resent-message-id return-path received
  list-help list-unsubscribe list-subscribe list-post list-owner list-archive
);

sub header_form_allowed {
  my ($field, $form) = @_;
  $form = _form_name($form);
  return 0 unless $GET_FORM{$form};
  return 1 if $form eq 'asRaw';
  return 1 unless $DEFINED_FIELD{ lc($field // '') };
  return $FORM_ALLOWED{$form}{ lc $field } ? 1 : 0;
}

my %SET_FORM = (
  asRaw              => \&_fmt_raw,
  asText             => \&_fmt_text,
  asAddresses        => \&_fmt_addresses,
  asGroupedAddresses => \&_fmt_grouped,
  asMessageIds       => \&_fmt_msgids,
  asDate             => \&_fmt_date,
  asURLs             => \&_fmt_urls,
);

sub format_header {
  my ($form, $value) = @_;
  $form = _form_name($form);
  my $fmt = $SET_FORM{$form} or die "Unknown header form '$form'\n";
  return undef unless defined $value;
  my $res = $fmt->($value);
  return undef unless defined $res;
  return $res if $form eq 'asRaw';
  return " $res";
}

sub _bad { my ($form, $why) = @_; die "Invalid $form header value: $why\n" }

sub _fmt_raw {
  my $v = shift;
  _bad(asRaw => 'not a string') if ref $v;
  _bad(asRaw => 'NUL') if $v =~ /\0/;
  # A line break is only allowed as a fold: CRLF then whitespace.
  (my $t = $v) =~ s/\r?\n(?=[ \t])//g;
  _bad(asRaw => 'line break that is not a fold') if $t =~ /[\r\n]/;
  return $v;
}

my $ATEXT = qr{[A-Za-z0-9!#\$%&'*+/=?^_`{|}~-]};

# RFC 2047 encoded-words for text that cannot go in a header as it is:
# non-ASCII, control characters (a line break would end the header), or
# something a reader would take for an encoded-word.
sub _needs_encoding { $_[0] =~ /[^\x20-\x7e\t]|=\?/ }

sub _encode_words {
  my $text = shift;
  my $enc = Encode::encode('MIME-Q', $text);
  $enc =~ s/\r?\n(?=[ \t])/\r\n/g;
  return $enc;
}

sub _fmt_text {
  my $v = shift;
  _bad(asText => 'not a string') if ref $v;
  $v =~ s/[\r\n]+/ /g;    # a header field cannot hold a line break
  return _needs_encoding($v) ? _encode_words($v) : $v;
}

# A phrase (display-name or group name): as-is if it is atoms, RFC 2047
# encoded-words if it needs them, else a quoted-string.
sub _fmt_phrase {
  my $phrase = shift;
  return _encode_words($phrase) if _needs_encoding($phrase);
  return $phrase if $phrase =~ m{\A$ATEXT+(?: $ATEXT+)*\z};
  (my $q = $phrase) =~ s/(["\\])/\\$1/g;
  return qq{"$q"};
}

# An addr-spec.  RFC 8621 S4.1.2.3 lets "email" lack the '@' (and S4.6
# lets a draft be invalid), so such a value is written as given; a local
# part that is not a dot-atom is quoted.  RFC 6532 UTF-8 is kept.
sub _fmt_addr_spec {
  my $email = shift;
  _bad(asAddresses => 'email is not a string') if !defined $email || ref $email;
  $email =~ s/[\r\n]+/ /g;    # nothing in it may end the header line
  _bad(asAddresses => "email '$email' has control characters") if $email =~ /[\x00-\x1f\x7f]/;
  my ($local, $domain) = $email =~ /\A(.*)\@([^@]*)\z/s ? ($1, $2) : ($email, undef);
  my $atom = qr{(?:$ATEXT|[^\x00-\x7f])+};
  if ($local !~ /\A"(?:[^"\\]|\\.)*"\z/ && $local !~ /\A$atom(?:\.$atom)*\z/) {
    $local =~ s/(["\\])/\\$1/g;
    $local = qq{"$local"};
  }
  if (defined $domain) {
    _bad(asAddresses => "bad domain in '$email'")
      if $domain !~ /\A\[[^\[\]\\]*\]\z/ && $domain =~ /[\s<>()\[\],;:\\"]/;
    return "$local\@$domain";
  }
  return $local;
}

sub _fmt_mailbox {
  my $a = shift;
  _bad(asAddresses => 'not an EmailAddress') unless ref $a eq 'HASH';
  my $spec = _fmt_addr_spec($a->{email});
  my $name = $a->{name};
  _bad(asAddresses => 'name is not a string') if ref $name;
  return (defined $name && $name ne '') ? _fmt_phrase($name) . " <$spec>" : $spec;
}

sub _fmt_addresses {
  my $v = shift;
  _bad(asAddresses => 'not a list') unless ref $v eq 'ARRAY';
  return join(', ', map { _fmt_mailbox($_) } @$v);
}

sub _fmt_grouped {
  my $v = shift;
  _bad(asGroupedAddresses => 'not a list') unless ref $v eq 'ARRAY';
  my @out;
  for my $g (@$v) {
    _bad(asGroupedAddresses => 'not an EmailAddressGroup')
      unless ref $g eq 'HASH' && ref $g->{addresses} eq 'ARRAY';
    my @mbox = map { _fmt_mailbox($_) } @{ $g->{addresses} };
    if (defined $g->{name}) {
      _bad(asGroupedAddresses => 'name is not a string') if ref $g->{name};
      push @out, _fmt_phrase($g->{name}) . ':' . (@mbox ? ' ' . join(', ', @mbox) : '') . ';';
    }
    else {
      push @out, @mbox;
    }
  }
  return join(', ', @out);
}

sub _fmt_msgids {
  my $v = shift;
  _bad(asMessageIds => 'not a list') unless ref $v eq 'ARRAY';
  return undef unless @$v;    # no msg-id at all reads back as null
  for my $id (@$v) {
    _bad(asMessageIds => 'not a string') if !defined $id || ref $id;
    _bad(asMessageIds => "'$id' is not a msg-id") if $id eq '' || $id =~ /[\s<>\x00-\x1f\x7f]/;
  }
  return join(' ', map { "<$_>" } @$v);
}

# RFC 3339 (a JMAP Date) in, RFC 5322 S3.3 date-time out, keeping the
# offset; asDate reads it back as the same instant and offset.
sub _fmt_date {
  my $v = shift;
  _bad(asDate => 'not a string') if ref $v;
  my ($y, $mo, $d, $h, $mi, $s, $tz) = $v =~
    /\A(\d{4})-(\d\d)-(\d\d)[Tt](\d\d):(\d\d):(\d\d)(?:\.\d+)?([Zz]|[-+]\d\d:\d\d)\z/
    or _bad(asDate => "'$v' is not an RFC 3339 date-time");
  $tz = $tz =~ /^[Zz]$/ ? '+0000' : $tz =~ s/://r;
  my $dt = eval {
    DateTime->new(year => $y, month => $mo, day => $d, hour => $h,
                  minute => $mi, second => $s, time_zone => $tz);
  } or _bad(asDate => "'$v' is not a valid date-time");
  return $dt->strftime('%a, %d %b %Y %H:%M:%S %z');
}

sub _fmt_urls {
  my $v = shift;
  _bad(asURLs => 'not a list') unless ref $v eq 'ARRAY';
  return undef unless @$v;    # no URL at all reads back as null
  for my $u (@$v) {
    _bad(asURLs => 'not a string') if !defined $u || ref $u;
    _bad(asURLs => "'$u' is not a URL") if $u eq '' || $u =~ /[\s<>\x00-\x1f\x7f]/;
  }
  return join(', ', map { "<$_>" } @$v);
}

# The header fields given by header:{name}[:as{form}][:all] properties
# on an Email or EmailBodyPart, as [Name, [Raw values]] in a stable
# order.  Dies on a property that is not valid for create.
sub _header_props {
  my $obj = shift;
  my @res;
  for my $key (sort grep { /^header:/ } keys %$obj) {
    my ($name, $form, $all) = parse_header_property($key)
      or die "Invalid header property '$key'\n";
    die "$form is not allowed for header $name\n" unless header_form_allowed($name, $form);
    my $val = $obj->{$key};
    next unless defined $val;
    my @vals;
    if ($all) {
      die "$key must be a list\n" unless ref $val eq 'ARRAY';
      @vals = @$val;
    }
    elsif ($form eq 'asRaw' && ref $val eq 'ARRAY') {
      @vals = @$val;    # a list of Raw values: one header field each
    }
    else {
      @vals = ($val);
    }
    push @res, [ $name, [ grep { defined } map { format_header($form, $_) } @vals ] ];
  }
  return @res;
}

# Write a Raw value (format_header's output, or one given) as is: the
# writer puts a space after the colon itself, so one leading space is
# dropped, and the value is written as UTF-8 octets.
sub _raw_for_write {
  my $v = shift;
  $v =~ s/\A //;
  $v = Encode::encode('UTF-8', $v) if Encode::is_utf8($v);
  return $v;
}

sub _set_raw_header {
  my ($mime, $name, $vals) = @_;
  $mime->header_raw_set($name => map { _raw_for_write($_) } @$vals);
}

# The Content-Transfer-Encoding for a leaf's octets.  make() ends by
# rewriting every line ending to CRLF, so whatever is written raw must
# survive that: text is 7bit, or quoted-printable when it has 8-bit or
# control octets or a line too long for SMTP; message/* is 7bit or 8bit
# (RFC 2046 S5.2.1 forbids anything else); everything else is base64,
# so binary octets never meet the rewrite.
sub _cte {
  my ($octets, $type) = @_;
  my $plain = $octets !~ /[^\x09\x0a\x0d\x20-\x7e]/ && $octets !~ /[^\n]{999}/;
  return $plain ? '7bit' : '8bit' if $type =~ m{^message/}i;
  return $plain ? '7bit' : 'quoted-printable' if $type =~ m{^text/}i;
  return 'base64';
}

sub _valid_cid {
  my $cid = shift;
  return 1 unless defined $cid;
  # Content-ID msg-id: no angle brackets, no whitespace, no NUL
  die "Invalid cid: must not contain < or >\n" if $cid =~ /[<>]/;
  die "Invalid cid: must not contain whitespace\n" if $cid =~ /\s/;
  die "Invalid cid: must not be empty\n" if $cid eq '';
  return 1;
}

# One leaf EmailBodyPart as a MIME part: the only place make() encodes
# body content, used for bodyStructure leaves and for the textBody,
# htmlBody and attachments shorthand alike.
#
# The content is the part's bodyValues value (characters, written as
# UTF-8) if it has a partId there, else its blob (octets, written as they
# are), else empty.  $opt{type} and $opt{disposition} are the defaults
# for a part that gives none; $opt{headers} (default true) applies the
# part's own header:* properties to it.
sub _leaf_part {
  my ($node, $bodyValues, $getblob, %opt) = @_;
  my $type = $node->{type} || $opt{type} || 'application/octet-stream';
  my $is_text = $type =~ m{^text/}i;

  my ($octets, $charset);
  my $partId = $node->{partId};
  if (defined $partId && $bodyValues->{$partId}) {
    my $value = $bodyValues->{$partId}{value} // '';
    $octets = Encode::encode('UTF-8', $value);
    $charset = $value =~ /[^\x00-\x7f]/ ? 'UTF-8' : 'us-ascii';
  }
  elsif ($node->{blobId} && $getblob) {
    my $btype;
    ($btype, $octets) = $getblob->($node->{blobId});
    $octets //= '';
    # Octets already; a wide character means the getblob gave text.
    $octets = Encode::encode('UTF-8', $octets) if $octets =~ /[^\x00-\xff]/;
    if ($is_text) {
      # S4.6: with a blobId, charset says what the octets are.  Else the
      # blob's own type may, else they are ASCII or UTF-8, or unknown.
      ($charset) = ($btype // '') =~ /;\s*charset\s*=\s*"?([^";\s]+)/i;
      $charset = $node->{charset} if $node->{charset};
      $charset //= $octets !~ /[^\x00-\x7f]/ ? 'us-ascii'
                 : _is_utf8_octets($octets) ? 'UTF-8' : undef;
    }
  }
  else {
    $octets = '';
    $charset = 'us-ascii';
  }
  # Text is written in canonical form, CRLF line ends (RFC 2046 S4.1.1):
  # the final rewrite makes every line end CRLF.
  $octets =~ s/\r\n/\n/g if $is_text;

  my %attrs = (content_type => $type, encoding => _cte($octets, $type));
  $attrs{charset} = $charset if $is_text && defined $charset;
  my $disp = $node->{disposition} || $opt{disposition};
  # these go into part headers as they are: a lone CR (which Email::MIME
  # lets through) or any control character would start a header of the
  # client's choosing in a parser that ends lines on CR
  die "Invalid disposition\n" if defined $disp && ($disp !~ /\A[A-Za-z0-9!#\$&^_.+-]{1,64}\z/);
  die "Invalid type\n" if $type =~ /[\x00-\x1f\x7f]/;
  $attrs{disposition} = $disp if $disp;
  $attrs{filename} = $attrs{name} = $node->{name} if $node->{name};

  my $mime = Email::MIME->create(attributes => \%attrs, body => $octets);

  if (defined $node->{cid}) {
    _valid_cid($node->{cid});
    $mime->header_str_set('Content-ID' => "<$node->{cid}>");
  }
  if ($node->{language} && ref($node->{language}) eq 'ARRAY') {
    # each a language tag (RFC 5646): letters, digits and hyphens
    die "Invalid language\n" if grep { ref || !defined || !/\A[A-Za-z0-9]{1,8}(?:-[A-Za-z0-9]{1,8})*\z/ } @{$node->{language}};
    $mime->header_str_set('Content-Language' => join(', ', @{$node->{language}}));
  }
  _apply_bodystructure_headers($mime, $node) if $opt{headers} // 1;
  return $mime;
}

sub _is_utf8_octets {
  my $copy = shift;
  return defined eval { Encode::decode('UTF-8', $copy, Encode::FB_CROAK) };
}

my $_uuid_gen;
sub default_header_defaults {
  my ($name) = @_;
  if (lc($name) eq 'date') {
    return Date::Format::time2str("%a, %d %b %Y %H:%M:%S %z", time());
  }
  if (lc($name) eq 'message-id') {
    $_uuid_gen ||= Data::UUID->new;
    my $uuid = $_uuid_gen->to_string($_uuid_gen->create);
    my $host = hostname();
    return "<$uuid\@$host>";
  }
  return undef;
}

sub _build_bodystructure {
  my ($node, $bodyValues, $getblob) = @_;

  my $type = $node->{type} || 'text/plain';

  if ($type =~ m{^multipart/}i) {
    # Multipart: recursively build subParts
    my @parts;
    for my $sub (@{$node->{subParts} || []}) {
      push @parts, _build_bodystructure($sub, $bodyValues, $getblob);
    }
    my $mime = Email::MIME->create(
      attributes => { content_type => $type },
      parts => \@parts,
    );
    # Apply header:* from this node
    _apply_bodystructure_headers($mime, $node);
    return $mime;
  }

  return _leaf_part($node, $bodyValues, $getblob, type => 'text/plain');
}

sub _apply_bodystructure_headers {
  my ($mime, $node) = @_;
  for my $h (_header_props($node)) {
    my ($hname, $vals) = @$h;
    # Skip Content-* headers that are managed by Email::MIME
    next if $hname =~ /^Content-/i;
    _set_raw_header($mime, $hname, $vals);
  }
}

sub make { _with_settings(\&_make, @_) }

sub _make {
  my $args = shift;
  my $getblob = shift;
  my $defaults_cb = shift || \&default_header_defaults;

  # RFC 8621 Email/set create format:
  #   from, to, cc, bcc, replyTo, sender: EmailAddress[]
  #   subject: String
  #   sentAt: Date (optional)
  #   messageId, inReplyTo, references: String[]
  #   textBody: EmailBodyPart[] (each with partId referencing bodyValues)
  #   htmlBody: EmailBodyPart[] (each with partId referencing bodyValues)
  #   bodyValues: Id[EmailBodyValue] (partId => {value: String})
  #   attachments: EmailBodyPart[] (each with blobId)

  # Follow RFC 8621 / Cyrus precedence:
  #   1. header:* properties (already converted from typed forms by caller)
  #   2. Convenience properties (only if header:* didn't set that header)
  #   3. Defaults (only if neither header:* nor convenience set the header)

  # Every header field is written through format_header, the inverse
  # of the header forms parse() reads, as [Name, [Raw values]].
  my @header = _header_props($args);
  my %have = map { lc($_->[0]) => 1 } @header;

  # Step 2: Convenience properties (skip if header:* already provides it)
  my @convenience = (
    [ from       => From          => 'asAddresses' ],
    [ to         => To            => 'asAddresses' ],
    [ cc         => Cc            => 'asAddresses' ],
    [ bcc        => Bcc           => 'asAddresses' ],
    [ subject    => Subject       => 'asText' ],
    [ sentAt     => Date          => 'asDate' ],
    [ messageId  => 'Message-ID'  => 'asMessageIds' ],
    [ inReplyTo  => 'In-Reply-To' => 'asMessageIds' ],
    [ references => References    => 'asMessageIds' ],
    [ replyTo    => 'Reply-To'    => 'asAddresses' ],
    [ sender     => Sender        => 'asAddresses' ],
  );
  for my $c (@convenience) {
    my ($prop, $name, $form) = @$c;
    next if $have{lc $name};
    my $val = format_header($form, $args->{$prop});
    next unless defined $val;
    push @header, [ $name, [ $val ] ];
    $have{lc $name} = 1;
  }
  if (!$have{date} && $args->{msgdate}) {
    push @header, [ Date => [ Date::Format::time2str("%a, %d %b %Y %H:%M:%S %z", $args->{msgdate}) ] ];
    $have{date} = 1;
  }

  # header:* on the textBody/htmlBody part go on the message, unless the
  # message already has that field.
  for my $partlist ($args->{textBody}, $args->{htmlBody}) {
    next unless $partlist && ref($partlist) eq 'ARRAY';
    for my $part (@$partlist) {
      for my $h (_header_props($part)) {
        next if $have{lc $h->[0]};
        push @header, $h;
        $have{lc $h->[0]} = 1;
      }
    }
  }

  # Step 3: Defaults via callback (only if nothing set them)
  for my $name (qw(Date Message-ID)) {
    next if $have{lc $name};
    my $val = $defaults_cb->($name);
    push @header, [ $name, [ $val ] ] if defined $val;
  }

  my $bodyValues = $args->{bodyValues} || {};

  # bodyStructure mode: build MIME tree from bodyStructure recursively
  if ($args->{bodyStructure}) {
    my $MIME = _build_bodystructure($args->{bodyStructure}, $bodyValues, $getblob);

    # Apply message-level headers to the top-level MIME part
    _set_raw_header($MIME, @$_) for @header;

    my $res = $MIME->as_string();
    $res =~ s/\r?\n/\r\n/gs;
    return $res;
  }

  # textBody/htmlBody: the first part with content (a partId in
  # bodyValues, or a blobId).  Its header:* properties went on the
  # message above.
  my $first_with_content = sub {
    my $list = shift;
    return undef unless $list && ref($list) eq 'ARRAY';
    for my $part (@$list) {
      return $part if defined $part->{partId} && $bodyValues->{$part->{partId}};
      return $part if $part->{blobId} && $getblob;
    }
    return undef;
  };

  # Note: do NOT auto-generate text/plain from HTML. Per RFC 8621,
  # if only htmlBody is provided, the server creates a single text/html
  # part that appears in both textBody and htmlBody of the response.
  # Generating a multipart/alternative would change the structure.

  my $MIME;
  my ($textpart, $htmlpart);
  if (my $part = $first_with_content->($args->{textBody})) {
    $textpart = _leaf_part({ %$part, type => 'text/plain' }, $bodyValues, $getblob, headers => 0);
  }
  if (my $part = $first_with_content->($args->{htmlBody})) {
    $htmlpart = _leaf_part({ %$part, type => 'text/html' }, $bodyValues, $getblob, headers => 0);
  }

  my @attparts;
  if ($args->{attachments} && ref($args->{attachments}) eq 'ARRAY') {
    for my $att (@{$args->{attachments}}) {
      next unless (defined $att->{partId} && $bodyValues->{$att->{partId}})
               || ($att->{blobId} && $getblob);
      push @attparts, _leaf_part($att, $bodyValues, $getblob,
        disposition => ($att->{isInline} ? 'inline' : 'attachment'));
    }
  }

  # Assemble the MIME structure
  if (@attparts) {
    my $body;
    if ($textpart && $htmlpart) {
      $body = Email::MIME->create(
        attributes => { content_type => 'multipart/alternative' },
        parts => [$textpart, $htmlpart],
      );
    }
    else {
      $body = $textpart || $htmlpart;
    }
    $MIME = Email::MIME->create(
      attributes => { content_type => 'multipart/mixed' },
      parts => [$body, @attparts],
    );
    _set_raw_header($MIME, @$_) for @header;
  }
  elsif ($textpart && $htmlpart) {
    $MIME = Email::MIME->create(
      attributes => { content_type => 'multipart/alternative' },
      parts => [$textpart, $htmlpart],
    );
    _set_raw_header($MIME, @$_) for @header;
  }
  elsif ($textpart) {
    # Add message headers to the existing part (preserves Content-ID etc.)
    _set_raw_header($textpart, @$_) for @header;
    $MIME = $textpart;
  }
  elsif ($htmlpart) {
    _set_raw_header($htmlpart, @$_) for @header;
    $MIME = $htmlpart;
  }
  else {
    $MIME = Email::MIME->create(
      attributes => { content_type => 'text/plain', charset => 'us-ascii' },
      body => '',
    );
    _set_raw_header($MIME, @$_) for @header;
  }

  my $res = $MIME->as_string();
  $res =~ s/\r?\n/\r\n/gs;

  return $res;
}

# Email::MIME, made to degrade one part instead of the whole message.
# Email::MIME splits every multipart while it is constructed, and dies
# (attempting the whole parse) when a part is nested deeper than
# $Email::MIME::MAX_DEPTH or the message has more than $MAX_PARTS parts.
# Here the part where that happens is kept whole as a single part, with
# its body intact, and every other part parses as before.  Subparts are
# made with ref($self)->_new, so the whole tree is of this class.
package Data::JSEmail::MIMEPart;
our @ISA = ('Email::MIME');

sub parts_multipart {
  my $self = shift;
  my $body = $self->Email::Simple::body;
  my @parts = eval { $self->SUPER::parts_multipart(@_) };
  return @parts unless $@;
  $self->Email::Simple::body_set($body);
  delete $self->{body_raw};
  return $self->parts_single_part;
}

package Data::JSEmail;

sub isodate {
  my $epoch = shift || time();
  my $date = DateTime->from_epoch( epoch => $epoch );
  return $date->iso8601() . 'Z';
}

sub parse_date {
  my $date = shift;
  return str2time($date);
}

sub htmltotext {
  my $html = shift;
  my $hs = HTML::Strip->new();
  my $clean_text = $hs->parse( $html );
  $hs->eof;
  return $clean_text;
}

1;

__END__

=head1 NAME

Data::JSEmail - Convert between Email::MIME and the JSON format from RFC 8621 (JMAP Mail)

=head1 HEADER FORMS

One codec for the parsed header forms of RFC 8621 S4.1.2, used in both
directions: C<parse> and C<make> use it for every header field they read
or write, the convenience properties (C<from>, C<subject>, C<sentAt>,
...) included.  A form is named as in a property: C<asText>,
C<asAddresses>, C<asGroupedAddresses>, C<asMessageIds>, C<asDate>,
C<asURLs>, and C<asRaw> for Raw (C<undef>, C<''> and C<'Raw'> mean
C<asRaw> too).

=head2 header_value($form, $raw_values, all => 0|1)

The value of a C<header:Name:$form[:all]> property, from the Raw value of
each instance of the field in message order (an arrayref; a single
string is taken as a one-item list; C<undef> items are skipped).
Without C<all>, the parsed value of the last instance, or C<undef> if
there is none; with C<all =E<gt> 1>, an arrayref of the parsed value of
each instance (C<[]> if none).  Dies (C<"Unknown header form '...'\n">)
for a form it does not know.

=head2 header_property($headers, $property)

C<header_value> over an EmailHeader list (C<[{name, value}, ...]>, the
C<headers> property C<parse> returns) for a whole property name such as
C<header:Resent-To:asAddresses:all>; names match case-insensitively.
Dies (C<"Invalid header property '...'\n">) when C<parse_header_property>
rejects the name.

=head2 parse_header_property($property)

C<($name, $form, $all)> for a valid C<header:{name}[:as{form}][:all]>
property (C<$form> is C<asRaw> when none is given, C<$all> is 0 or 1),
or the empty list if the name is not a header property, the field name
is not printable ASCII without a colon (S4.1.3), or the form is unknown.
It does not consult C<header_form_allowed>.

=head2 format_header($form, $value)

The create side, the inverse of C<header_value> for one instance: the
Raw value (with the usual leading space) to write for C<$value> in
C<$form>, such that C<header_value($form, [$raw])> gives C<$value> back.
The result is a character string; C<make> writes it as UTF-8.

=over 4

=item asText: RFC 2047 encoded-words (UTF-8, Q) when the text is not
printable ASCII or holds something that looks like an encoded-word
(C<=?>); line breaks become spaces.

=item asAddresses: C<name E<lt>emailE<gt>> or a bare C<email>, comma
separated.  A name is written as atoms, as a quoted-string (C<"> and
C<\> escaped), or as encoded-words if it is not ASCII or contains
C<=?>.  A local part that is not a dot-atom is quoted.  An C<email>
without an C<@> is written as given (S4.1.2.3 allows it, and S4.6 lets a
draft be invalid); RFC 6532 UTF-8 addresses are kept.  C<[]> gives an
empty value.

=item asGroupedAddresses: as asAddresses, with each group that has a
name written as C<Name: mailbox, ...;> (C<Name:;> when empty) and the
mailboxes of a group with a null name written ungrouped.

=item asMessageIds: C<E<lt>idE<gt>> separated by spaces; C<[]> gives
C<undef> (no field: an empty one would read back as null, not []).

=item asDate: an RFC 3339 date-time (a JMAP Date) written as an RFC 5322
date-time, keeping the offset: C<2026-11-07T10:00:00+11:00> becomes
C<Sat, 07 Nov 2026 10:00:00 +1100>; C<Z> becomes C<+0000>.

=item asURLs: C<E<lt>urlE<gt>> separated by commas; C<[]> gives
C<undef>.

=item asRaw: the value as given.

=back

A C<$value> of C<undef> gives C<undef> (no header field).  A value of
the wrong type or shape dies with C<"Invalid $form header value: ...\n">:
for example a Date that is not RFC 3339 or not a real date, a message
id or URL that is empty or holds whitespace or angle brackets, an
EmailAddress without a string C<email>, a domain with spaces or
specials, a Raw value with NUL or with a line break that is not a fold
(CRLF then whitespace).  An unknown form dies like C<header_value>.

=head2 header_form_allowed($field, $form)

1 if the parsed form may be used with that header field (the table in
RFC 8621 S4.1.2: Raw is allowed for every field; a field defined in RFC
5322 or RFC 2369 only with the forms listed for it; any other field with
every form), else 0.  An unknown form is 0.

=head2 Header properties in make

C<make> takes C<header:{name}[:as{form}][:all]> properties on the Email
and on any EmailBodyPart directly: each is checked with
C<parse_header_property> and C<header_form_allowed> and written with
C<format_header>; C<:all> takes a list and writes one field per item, and
a Raw value given as a list does the same.  A Raw value is written as
given, less one leading space (the writer puts one after the colon).
C<make> dies on an invalid property name, a form not allowed for the
field, a value C<format_header> refuses, or an C<:all> value that is not a
list.  A C<header:*> property wins over the convenience property for the
same field.

=head1 AUTHOR

Bron Gondwana, C<< <brong at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Fastmail Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself; that is, either the GNU General
Public License as published by the Free Software Foundation (version 1,
or at your option any later version), or the Artistic License.

See L<http://dev.perl.org/licenses/> and the LICENSE file included with
this distribution for more information.

=cut
