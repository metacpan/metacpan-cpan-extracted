#!/usr/bin/perl -cw

use strict;
use warnings;

package Data::JSEmail;

our $VERSION = '0.01';

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
    if ($type->{type} eq 'text') {
      $values->{$partno} = {
        value => $body,
        isEncodingProblem => $JSON::false,
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
      size => length($body),
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
  $val =~ s/\(.*//;
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

# NOTE: this is totally bogus..
sub asURLs {
  my $val = shift;
  return undef unless defined $val;
  unless ($val =~ m/\<.*\>/) {
    $val =~ s/^\s+//;
    $val =~ s/ .*//; # strip everything after first whitespace
    return undef unless length($val);
    return [$val];
  }

  my @list;
  while ($val =~ m/<([^>]+)>/gs) {
    push @list, $1;
  }
  return \@list;
}

sub asOneURL {
  my $val = shift;
  my $list = asURLs($val) || [];
  return $list->[-1];
}

sub asText {
  my $val = shift;
  return undef unless defined $val;
  my $res = encode_utf8(NFC(decode('MIME-Header', $val)));
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

sub asGroupAddresses {
  my $emails = shift;

  return undef unless defined $emails;
  my $addrs = Email::MIME::Header::AddressList->from_mime_string($emails);
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
  my @list = $eml->header_obj->header_raw_pairs();
  my @res;
  while (@list) {
   my $name = shift @list;
   my $value = shift @list;
    push @res, {
      name => $name,
      value => $value,
    };
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

  for (my $i = 0; $i < @$parts; $i++) {
    my $part = $parts->[$i];
    my $isMultipart = $part->{type} =~ m{^multipart/(.*)};
    my $subMultiType = $isMultipart ? $1 : '';
    my $isInline = ($part->{disposition}//'none') ne 'attachment' &&
        # Must be one of the allowed body types
        ( $part->{type} eq 'text/plain' ||
          $part->{type} eq 'text/html' ||
          isInlineMediaType($part->{type}) ) &&
        # If multipart/related, only the first part can be inline
        # If a text part with a filename, and not the first item in the
        # multipart, assume it is an attachment
        ($i == 0 ||
            ( $multipartType ne 'related' &&
                ( isInlineMediaType($part->{type}) || !$part->{name} ) ) );

    if ($isMultipart) {
      parseStructure($part->{subParts}, $subMultiType,
          $inAlternative || ( $subMultiType eq 'alternative' ),
          $textBody, $htmlBody, $attachments);
    }
    elsif ($isInline) {
      if ($multipartType eq 'alternative') {
        if ($part->{type} eq 'text/plain') {
          push @$textBody, $part;
          next; #part
        }
        elsif ($part->{type} eq 'text/html') {
          push @$htmlBody, $part;
          next; #part
        }
      }
      push @$textBody, $part;
      push @$htmlBody, $part;
    }
    else {
      push @$attachments, $part;
    }
  }

  # XXX - handle "we didn't find a matching part in a current alternative for text/plain AND text/html
}

sub _mkone {
  my $h = shift;
  if ($h->{name} ne '') {
    return "\"$h->{name}\" <$h->{email}>";
  }
  else {
    return "$h->{email}";
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

sub _makeatt {
  my $att = shift;
  my $getblob = shift;

  my %attributes = (
    content_type => $att->{type},
    name => $att->{name},
    filename => $att->{name},
    disposition => $att->{isInline} ? 'inline' : 'attachment',
  );

  my %headers;
  if ($att->{cid}) {
    $headers{'Content-ID'} = "<$att->{cid}>";
  }

  my ($type, $content) = $getblob->($att->{blobId});

  $attributes{encoding} = _detect_encoding($content, $att->{type});

  return Email::MIME->create(
    attributes => \%attributes,
    headers => \%headers,
    body => $content,
  );
}

sub make {
  my $args = shift;
  my $getblob = shift;

  my @header = (
    From => _mkemail($args->{from}),
    To => _mkemail($args->{to}),
    Cc => _mkemail($args->{cc}),
    Bcc => _mkemail($args->{bcc}),
    Subject => $args->{subject},
    Date => Date::Format::time2str("%a, %d %b %Y %H:%M:%S %z", $args->{msgdate}),
  );
  if ($args->{messageId} && @{$args->{messageId}}) {
    push @header, 'Message-ID' => '<' . $args->{messageId}[0] . '>';
  }
  if ($args->{inReplyTo} && @{$args->{inReplyTo}}) {
    push @header, 'In-Reply-To' => join(' ', map { "<$_>" } @{$args->{inReplyTo}});
  }
  if ($args->{references} && @{$args->{references}}) {
    push @header, 'References' => join(' ', map { "<$_>" } @{$args->{references}});
  }
  if ($args->{replyTo}) {
    push @header, 'Reply-To' => _mkemail($args->{replyTo});
  }

  # massive switch
  my $MIME;
  my $htmlpart;
  my $text = $args->{textBody} ? $args->{textBody} : htmltotext($args->{htmlBody});
  my $textpart = Email::MIME->create(
    attributes => {
      content_type => 'text/plain',
      charset => 'UTF-8',
    },
    body => Encode::encode_utf8($text),
  );
  if ($args->{htmlBody}) {
    $htmlpart = Email::MIME->create(
      attributes => {
        content_type => 'text/html',
        charset => 'UTF-8',
      },
      body => Encode::encode_utf8($args->{htmlBody}),
    );
  }

  my @attachments = $args->{attachments} ? @{$args->{attachments}} : ();

  if (@attachments) {
    my @attparts = map { _makeatt($_, $getblob) } @attachments;
    # most complex case
    if ($htmlpart) {
      my $msgparts = Email::MIME->create(
        attributes => {
          content_type => 'multipart/alternative'
        },
        parts => [$textpart, $htmlpart],
      );
      $MIME = Email::MIME->create(
        header_str => [@header, 'Content-Type' => 'multipart/mixed'],
        parts => [$msgparts, @attparts],
      );
    }
    else {
      $MIME = Email::MIME->create(
        header_str => [@header, 'Content-Type' => 'multipart/mixed'],
        parts => [$textpart, @attparts],
      );
    }
  }
  else {
    if ($htmlpart) {
      $MIME = Email::MIME->create(
        attributes => {
          content_type => 'multipart/alternative',
        },
        header_str => \@header,
        parts => [$textpart, $htmlpart],
      );
    }
    else {
      $MIME = Email::MIME->create(
        attributes => {
          content_type => 'text/plain',
          charset => 'UTF-8',
        },
        header_str => \@header,
        body => $args->{textBody},
      );
    }
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
