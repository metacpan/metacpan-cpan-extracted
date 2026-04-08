#!/usr/bin/perl -cw

use strict;
use warnings;

package Data::JSEmail;

our $VERSION = '0.03';

use JSON;
use JSON::XS;
use HTML::Strip;
use Email::MIME;
use Email::MIME::ContentType;
use Email::MIME::Header::AddressList;
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

sub parse {
  my $rfc822 = shift;
  my $id = shift || Digest::SHA::sha256_hex($rfc822);
  my $eml = Email::MIME->new($rfc822);
  my $res = parse_email($id, $eml);
  $res->{size} = length($rfc822);
  return $res;
}

sub parse_email {
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
  my $data = {
    id => $id,
    sender => asAddresses($eml->header('Sender')),
    to => asAddresses($eml->header('To')),
    cc => asAddresses($eml->header('Cc')),
    bcc => asAddresses($eml->header('Bcc')),
    from => asAddresses($eml->header('From')),
    replyTo => asAddresses($eml->header('Reply-To')),
    subject => asText($eml->header('Subject')),
    sentAt => asDate($eml->header('Date')),
    messageId => asMessageIds($eml->header('Message-Id')),
    references => asMessageIds($eml->header('References')),
    inReplyTo => asMessageIds($eml->header('In-Reply-To')),
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
      push @sub, bodystructure($values, $id, $parts[$n-1], $partno ? "$partno.$n" : $n);
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
      $values->{$partno} = {
        value => $text_body,
        isEncodingProblem => (defined $decoded ? $JSON::false : $JSON::true),
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

sub asDate {
  my $val = shift;
  return undef unless defined $val;
  $val =~ s/\(.*//;  # strip comments
  $val =~ s/^\s+//;  # strip leading whitespace
  $val =~ s/\s+$//;  # strip trailing whitespace
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
  $val =~ s/\s+$//;
  my @list = split /\s*,\s*/, $val;
  return \@list;
}

sub asURLs {
  my $val = shift;
  return undef unless defined $val;
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;
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
  $res =~ s/\s*$//;
  return $res;
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
  my $addrs = eval { Email::MIME::Header::AddressList->from_mime_string($emails) };
  return undef unless $addrs;
  my @addrs = $addrs->groups();
  my @res;
  while (@addrs) {
    my $group = shift @addrs;
    my $list = shift @addrs;
    my @addresses;
    foreach my $addr (@$list) {
      my $name = $addr->phrase();
      my $email = $addr->address();
      $email =~ s/\@(.*)/"@" . lc($1)/e if $email;
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
  my $addrs = eval { Email::MIME::Header::AddressList->from_mime_string($emails) };
  return undef unless $addrs;
  my @addrs = $addrs->groups();
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
      my $email = $addr->address();
      $email =~ s/\@(.*)/"@" . lc($1)/e;
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
    return make_preview(htmltotext($text));
  }
  foreach my $sub ($eml->subparts()) {
    my $res = preview($sub);
    return $res if $res;
  }
  return undef;
}

sub make_preview {
  my $text = shift;
  $text =~ s/\s+/ /gs;
  return substr($text, 0, 256);
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
    my $isMultipart = $part->{type} =~ m{^multipart/(.*)};
    my $subMultiType = $isMultipart ? $1 : '';

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

sub _mkone {
  my $h = shift;
  my $email = $h->{email};
  my $name = $h->{name};
  if (defined $name && $name ne '') {
    return qq{"$name" <$email>};
  }
  else {
    return $email;
  }
}

sub _mkemail {
  my $a = shift;
  return join(", ", map { _mkone($_) } @$a);
}

sub _detect_encoding {
  my $content = shift;
  my $type = shift;

  if ($type =~ m/^message/) {
    if ($content =~ m/[^\x{09}\x{0a}\x{0d}\x{20}-\x{7e}]/) {
      return '8bit';
    }
    return '7bit';
  }

  if ($type =~ m/^text/) {
    # XXX - also line lengths?
    if ($content =~ m/[^\x{09}\x{0a}\x{0d}\x{20}-\x{7e}]/) {
      return 'quoted-printable';
    }
    return '7bit';
  }

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

sub _makeatt {
  my $att = shift;
  my $getblob = shift;

  my $disp = $att->{disposition} || ($att->{isInline} ? 'inline' : 'attachment');

  my %attributes = (
    content_type => $att->{type} || 'application/octet-stream',
    disposition => $disp,
  );
  $attributes{name} = $att->{name} if $att->{name};
  $attributes{filename} = $att->{name} if $att->{name};

  my ($type, $content) = $getblob->($att->{blobId});
  $content //= '';

  $attributes{encoding} = _detect_encoding($content, $attributes{content_type});

  my $part = Email::MIME->create(
    attributes => \%attributes,
    body => $content,
  );

  if ($att->{cid}) {
    _valid_cid($att->{cid});
    $part->header_str_set('Content-ID' => "<$att->{cid}>");
  }
  if ($att->{language} && ref($att->{language}) eq 'ARRAY') {
    $part->header_str_set('Content-Language' => join(', ', @{$att->{language}}));
  }

  return $part;
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

sub _apply_headers {
  my ($mime, $headers) = @_;
  while (@$headers) {
    my $name = shift @$headers;
    my $val = shift @$headers;
    next unless defined $val;
    if (ref($val) eq 'ARRAY') {
      $mime->header_str_set($name => @$val);
    } else {
      $mime->header_str_set($name => $val);
    }
  }
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

  # Leaf part: get content from partId/bodyValues or blobId
  my $content = '';
  if ($node->{partId} && $bodyValues->{$node->{partId}}) {
    $content = $bodyValues->{$node->{partId}}{value} // '';
  } elsif ($node->{blobId} && $getblob) {
    my ($btype, $bcontent) = $getblob->($node->{blobId});
    $content = $bcontent // '';
  }

  my $charset = 'us-ascii';
  if ($type =~ m{^text/}i) {
    $charset = ($content =~ /[^\x{00}-\x{7f}]/) ? 'UTF-8' : 'us-ascii';
  }

  my %attrs = (content_type => $type);
  $attrs{charset} = $charset if $type =~ m{^text/}i;
  $attrs{disposition} = $node->{disposition} if $node->{disposition};
  $attrs{filename} = $node->{name} if $node->{name};
  $attrs{name} = $node->{name} if $node->{name};

  my $body = ($charset eq 'UTF-8' && $type =~ m{^text/}i)
    ? Encode::encode_utf8($content) : $content;

  my $mime = Email::MIME->create(
    attributes => \%attrs,
    body => $body,
  );

  # Set body part metadata
  if (defined $node->{cid}) {
    _valid_cid($node->{cid});
    $mime->header_str_set('Content-ID' => "<$node->{cid}>");
  }
  if ($node->{language} && ref($node->{language}) eq 'ARRAY') {
    $mime->header_str_set('Content-Language' => join(', ', @{$node->{language}}));
  }

  # Apply header:* from this node
  _apply_bodystructure_headers($mime, $node);

  return $mime;
}

sub _apply_bodystructure_headers {
  my ($mime, $node) = @_;
  for my $key (keys %$node) {
    next unless $key =~ /^header:(.+)/;
    my $hname = $1;
    my $hval = $node->{$key};
    # Skip Content-* headers that are managed by Email::MIME
    next if $hname =~ /^Content-/i;
    if (ref($hval) eq 'ARRAY') {
      $mime->header_str_set($hname => @$hval);
    } else {
      $mime->header_str_set($hname => $hval) if defined $hval;
    }
  }
}

sub make {
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

  # Step 1: Collect top-level header:* overrides into a lookup
  my %header_override;  # lc(name) => 1
  for my $key (keys %$args) {
    next unless $key =~ /^header:(.+)/;
    $header_override{lc $1} = 1;
  }

  my @header;

  # Step 2: Convenience properties (skip if header:* already provides it)
  push @header, From => _mkemail($args->{from})
    if $args->{from} && !$header_override{from};
  push @header, To => _mkemail($args->{to})
    if $args->{to} && !$header_override{to};
  push @header, Cc => _mkemail($args->{cc})
    if $args->{cc} && !$header_override{cc};
  push @header, Bcc => _mkemail($args->{bcc})
    if $args->{bcc} && !$header_override{bcc};
  push @header, Subject => $args->{subject}
    if defined($args->{subject}) && !$header_override{subject};
  if (!$header_override{date}) {
    if ($args->{sentAt}) {
      push @header, Date => $args->{sentAt};
    }
    elsif ($args->{msgdate}) {
      push @header, Date => Date::Format::time2str("%a, %d %b %Y %H:%M:%S %z", $args->{msgdate});
    }
  }
  if ($args->{messageId} && ref($args->{messageId}) eq 'ARRAY' && @{$args->{messageId}}
      && !$header_override{'message-id'}) {
    push @header, 'Message-ID' => join(' ', map { "<$_>" } @{$args->{messageId}});
  }
  if ($args->{inReplyTo} && ref($args->{inReplyTo}) eq 'ARRAY' && @{$args->{inReplyTo}}
      && !$header_override{'in-reply-to'}) {
    push @header, 'In-Reply-To' => join(' ', map { "<$_>" } @{$args->{inReplyTo}});
  }
  if ($args->{references} && ref($args->{references}) eq 'ARRAY' && @{$args->{references}}
      && !$header_override{references}) {
    push @header, 'References' => join(' ', map { "<$_>" } @{$args->{references}});
  }
  push @header, 'Reply-To' => _mkemail($args->{replyTo})
    if $args->{replyTo} && !$header_override{'reply-to'};
  push @header, Sender => _mkemail($args->{sender})
    if $args->{sender} && !$header_override{sender};

  # Step 2b: Add all header:* values
  for my $key (keys %$args) {
    next unless $key =~ /^header:(.+)/;
    push @header, $1 => $args->{$key};
  }
  for my $partlist ($args->{textBody}, $args->{htmlBody}) {
    next unless $partlist && ref($partlist) eq 'ARRAY';
    for my $part (@$partlist) {
      for my $key (keys %$part) {
        next unless $key =~ /^header:(.+)/;
        my $hname = $1;
        # Only add if not already set by top-level header:* or convenience
        my %have_so_far = map { lc($header[$_]) => 1 } grep { $_ % 2 == 0 } 0..$#header;
        push @header, $hname => $part->{$key} unless $have_so_far{lc $hname};
      }
    }
  }

  # Step 3: Defaults via callback (only if nothing set them)
  my %have = map { lc($header[$_]) => 1 } grep { $_ % 2 == 0 } 0..$#header;
  for my $name (qw(Date Message-ID)) {
    next if $have{lc $name};
    my $val = $defaults_cb->($name);
    push @header, $name => $val if defined $val;
  }

  my $bodyValues = $args->{bodyValues} || {};

  # bodyStructure mode: build MIME tree from bodyStructure recursively
  if ($args->{bodyStructure}) {
    my $MIME = _build_bodystructure($args->{bodyStructure}, $bodyValues, $getblob);

    # Apply message-level headers to the top-level MIME part
    while (@header) {
      my $name = shift @header;
      my $val = shift @header;
      if (ref($val) eq 'ARRAY') {
        # :all style - set multiple values
        $MIME->header_str_set($name => @$val);
      } else {
        $MIME->header_str_set($name => $val) if defined $val;
      }
    }

    my $res = $MIME->as_string();
    $res =~ s/\r?\n/\r\n/gs;
    return $res;
  }

  # Extract body content from bodyValues via textBody/htmlBody part references

  my $textContent;
  my $htmlContent;
  my %textMeta;   # cid, language, disposition, name from body part
  my %htmlMeta;

  if ($args->{textBody} && ref($args->{textBody}) eq 'ARRAY') {
    for my $part (@{$args->{textBody}}) {
      my $partId = $part->{partId};
      if ($partId && $bodyValues->{$partId}) {
        $textContent = $bodyValues->{$partId}{value};
        %textMeta = map { $_ => $part->{$_} } grep { defined $part->{$_} } qw(cid language disposition name);
        last;
      }
      if ($part->{blobId} && $getblob) {
        my ($type, $content) = $getblob->($part->{blobId});
        $textContent = $content;
        %textMeta = map { $_ => $part->{$_} } grep { defined $part->{$_} } qw(cid language disposition name);
        last;
      }
    }
  }

  if ($args->{htmlBody} && ref($args->{htmlBody}) eq 'ARRAY') {
    for my $part (@{$args->{htmlBody}}) {
      my $partId = $part->{partId};
      if ($partId && $bodyValues->{$partId}) {
        $htmlContent = $bodyValues->{$partId}{value};
        %htmlMeta = map { $_ => $part->{$_} } grep { defined $part->{$_} } qw(cid language disposition name);
        last;
      }
      if ($part->{blobId} && $getblob) {
        my ($type, $content) = $getblob->($part->{blobId});
        $htmlContent = $content;
        %htmlMeta = map { $_ => $part->{$_} } grep { defined $part->{$_} } qw(cid language disposition name);
        last;
      }
    }
  }

  # Note: do NOT auto-generate text/plain from HTML. Per RFC 8621,
  # if only htmlBody is provided, the server creates a single text/html
  # part that appears in both textBody and htmlBody of the response.
  # Generating a multipart/alternative would change the structure.

  # Build MIME parts
  my $MIME;
  my $textpart;
  my $htmlpart;

  if (defined $textContent) {
    my $charset = ($textContent =~ /[^\x{00}-\x{7f}]/) ? 'UTF-8' : 'us-ascii';
    my %attrs = (content_type => 'text/plain', charset => $charset);
    $attrs{disposition} = $textMeta{disposition} if $textMeta{disposition};
    $attrs{filename} = $textMeta{name} if $textMeta{name};
    $attrs{name} = $textMeta{name} if $textMeta{name};
    $textpart = Email::MIME->create(
      attributes => \%attrs,
      body => $charset eq 'UTF-8' ? Encode::encode_utf8($textContent) : $textContent,
    );
    if ($textMeta{cid}) {
      _valid_cid($textMeta{cid});
      $textpart->header_str_set('Content-ID' => "<$textMeta{cid}>");
    }
    if ($textMeta{language} && ref($textMeta{language}) eq 'ARRAY') {
      $textpart->header_str_set('Content-Language' => join(', ', @{$textMeta{language}}));
    }
  }

  if (defined $htmlContent) {
    my $charset = ($htmlContent =~ /[^\x{00}-\x{7f}]/) ? 'UTF-8' : 'us-ascii';
    my %attrs = (content_type => 'text/html', charset => $charset);
    $attrs{disposition} = $htmlMeta{disposition} if $htmlMeta{disposition};
    $attrs{filename} = $htmlMeta{name} if $htmlMeta{name};
    $attrs{name} = $htmlMeta{name} if $htmlMeta{name};
    $htmlpart = Email::MIME->create(
      attributes => \%attrs,
      body => $charset eq 'UTF-8' ? Encode::encode_utf8($htmlContent) : $htmlContent,
    );
    if ($htmlMeta{cid}) {
      _valid_cid($htmlMeta{cid});
      $htmlpart->header_str_set('Content-ID' => "<$htmlMeta{cid}>");
    }
    if ($htmlMeta{language} && ref($htmlMeta{language}) eq 'ARRAY') {
      $htmlpart->header_str_set('Content-Language' => join(', ', @{$htmlMeta{language}}));
    }
  }

  my @attparts;
  if ($args->{attachments} && ref($args->{attachments}) eq 'ARRAY') {
    for my $att (@{$args->{attachments}}) {
      if ($att->{partId} && $bodyValues->{$att->{partId}}) {
        # Content from bodyValues
        my $content = $bodyValues->{$att->{partId}}{value} // '';
        my $disp = $att->{disposition} || 'attachment';
        my %attrs = (
          content_type => $att->{type} || 'application/octet-stream',
          disposition => $disp,
        );
        $attrs{filename} = $att->{name} if $att->{name};
        $attrs{name} = $att->{name} if $att->{name};
        $attrs{encoding} = _detect_encoding($content, $attrs{content_type});
        my $part = Email::MIME->create(attributes => \%attrs, body => $content);
        if ($att->{cid}) {
          _valid_cid($att->{cid});
          $part->header_str_set('Content-ID' => "<$att->{cid}>");
        }
        $part->header_str_set('Content-Language' => join(', ', @{$att->{language}}))
          if $att->{language} && ref($att->{language}) eq 'ARRAY';
        push @attparts, $part;
      }
      elsif ($att->{blobId} && $getblob) {
        push @attparts, _makeatt($att, $getblob);
      }
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
    _apply_headers($MIME, \@header);
  }
  elsif ($textpart && $htmlpart) {
    $MIME = Email::MIME->create(
      attributes => { content_type => 'multipart/alternative' },
      parts => [$textpart, $htmlpart],
    );
    _apply_headers($MIME, \@header);
  }
  elsif ($textpart) {
    # Add message headers to the existing part (preserves Content-ID etc.)
    _apply_headers($textpart, \@header);
    $MIME = $textpart;
  }
  elsif ($htmlpart) {
    _apply_headers($htmlpart, \@header);
    $MIME = $htmlpart;
  }
  else {
    $MIME = Email::MIME->create(
      attributes => { content_type => 'text/plain', charset => 'us-ascii' },
      body => '',
    );
    _apply_headers($MIME, \@header);
  }

  my $res = $MIME->as_string();
  $res =~ s/\r?\n/\r\n/gs;

  return $res;
}

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
