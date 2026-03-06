package Crypt::SecretBuffer::PEM;
# VERSION
# ABSTRACT: Parse PEM format from a SecretBuffer
$Crypt::SecretBuffer::PEM::VERSION = '0.019';
use strict;
use warnings;
use Carp;
use Scalar::Util qw( blessed );
use Crypt::SecretBuffer qw/ secret span MATCH_NEGATE MATCH_REVERSE MATCH_ANCHORED MATCH_MULTI ISO8859_1 BASE64 /;


sub parse {
   my ($class, $span, %options)= @_;
   my $secret_headers= !!$options{secret_headers};
   my $notrim= !exists $options{trim_headers}? 0 : !$options{trim_headers};
   while (my $begin= $span->scan("-----BEGIN ")) {
      $span->pos($begin->lim);
      my $label= $span->parse(qr/[A-Z0-9 ]+/);
      next unless $label && $span->parse("-----\n");
      $begin->lim($span->pos);
      my $label_str= '';
      $label->copy_to($label_str);
      # back up the span by 1 char so that it starts with \n, just in case there is an END
      # line immediately following the BEGIN line.
      $span->pos($span->pos-1);
      my $end= $span->scan("\n-----END $label_str-----");
      unless ($end) {
         carp "PEM begin marker for $label_str lacks an END marker";
         next;
      }
      $end->ltrim("\n");
      $span->pos($end->lim);
      $span->ltrim("\r");
      $span->ltrim("\n"); # consume line ending

      # Let block be its own SecretBuffer
      my $block= $span->clone(pos => $begin->pos, lim => $span->pos)->copy;
      my $inner= $block->span(pos => $begin->len, lim => $end->pos - $begin->pos);
      if (!$block->span($end->pos - $begin->pos - 1, 1)->ends_with("\n")) {
         carp "PEM end marker found not at the start of a line";
         next;
      }
      # Treat each line containing a ":" as a "name: value" header
      my @headers;
      while (my $sep_or_eol= $inner->scan(qr/[:\n]/)) {
         if ($sep_or_eol->starts_with(':')) {
            my ($name, $value);
            my $name_span= $inner->clone(lim => $sep_or_eol->pos);
            $name_span->trim unless $notrim;
            $name_span->copy_to($name);
            $inner->pos($sep_or_eol->lim);
            my $eol= $inner->scan("\n") or die "BUG"; # inner ends with "\n", checked above
            my $val_span= $inner->clone(lim => $eol->pos);
            # notrim means don't remove arbitrary leading/trailing whitespace.
            # the space char after ':' is part of the specification, so should be removed.
            $notrim? $val_span->ltrim(' ') : $val_span->trim;
            $inner->pos($eol->lim);
            if ($secret_headers) {
               push @headers, $name, $val_span;
            } else {
               $val_span->copy_to($value);
               push @headers, $name, $value;
            }
         }
         else {
            # If any headers were found, there needs to be a blank line
            if (@headers) {
               if ($sep_or_eol->pos == $inner->pos) { # "\n" at start of 'inner'
                  $inner->pos($sep_or_eol->lim);
               } else {
                  carp "PEM headers for $label_str did not end with a blank line"
               }
            }
            last;
         }
      }
      $inner->encoding(BASE64);
      return $class->new(
         buffer => $block,
         label => $label_str,
         header_kv => \@headers,
         content => $inner,
      );
   }
   return undef;
}

sub parse_all {
   my ($class, $span, %options)= @_;
   my @pem;
   while (my $pem= $class->parse($span, %options)) {
      push @pem, $pem;
   }
   return @pem;
}

sub new {
   my $class= shift;
   my $self= bless {}, $class;
   while (@_) {
      my ($attr, $val)= splice(@_, 0, 2);
      $self->$attr($val);
   }
   $self;
}


sub buffer         { $_[0]{buffer}=  $_[1] if @_ > 1; $_[0]{buffer} }
sub label          { $_[0]{label}=   $_[1] if @_ > 1; $_[0]{label} }
sub content        { $_[0]{content}= $_[1] if @_ > 1; $_[0]{content} }
sub header_kv {
   if (@_ > 1) {
      _validate_header_kv($_[1]);
      $_[0]{header_kv}= $_[1];
      $_[0]{headers}->raw_kv_array($_[1])
         if defined $_[0]{headers};
   }
   $_[0]{header_kv}
}
sub headers {
   my $self= shift;
   require Crypt::SecretBuffer::PEM::Headers;
   $self->{headers} ||=
      Crypt::SecretBuffer::PEM::Headers
         ->new(raw_kv_array => $self->header_kv)
         ->_create_tied_hashref;
}

sub _validate_header_kv {
   my $kv= shift;
   croak "Expected even-length arrayref"
      unless ref $kv eq 'ARRAY' && ($#$kv & 1);
   for (0..($#$kv-1)/2) {
      my ($k, $v)= ($kv->[$_*2], $kv->[$_*2+1]);
      croak "PEM header Key is undefined"
         unless defined $k;
      croak "PEM Header name '$k' contains wide characters"
         unless utf8::downgrade($k, 1);
      # Sanity checks, key cannot contain control chars or ':' or leading or trailing whitespace
      croak "PEM Header name '$k' contains ':' or control characters"
         if $k =~ /[\0-\x1F\x7F:]/;
      carp "PEM header name '$k' contains leading/trailing whitespace"
         if $k =~ /^\s/ or $k =~ /\s\z/;
      croak "PEM header value for '$k' is undefined"
         unless defined $v;
      my $is_secret= blessed($v) && ($v->isa('Crypt::SecretBuffer::Span') || $v->isa('Crypt::SecretBuffer'));
      croak "PEM header value for $k' contains wide characters"
         unless $is_secret || utf8::downgrade($v, 1);
      croak "PEM header value for '$k' contains control characters"
         if $is_secret? ($v->scan(qr/[\0-\x1F\x7F]/))
                      : ($v =~ /[\0-\x1F\x7F]/);
      carp "PEM header value for '$k' contains leading/trailing whitespace"
         if $is_secret? ($v->scan(qr/[\s]/, MATCH_ANCHORED) or $v->scan(qr/[\s]/, MATCH_ANCHORED|MATCH_REVERSE))
                      : ($v =~ /^\s/ or $v =~ /\s\z/);
   }
   1;
}


sub serialize {
   my $self= shift;
   my $out= secret('-----BEGIN '.$self->label."-----\n");
   my @header_kv= @{ $self->header_kv || [] };
   if (@header_kv) {
      # re-validate since individual values are mutable and may have changed since the
      # attribute was assigned.
      _validate_header_kv(\@header_kv);
      for (0..$#header_kv) {
         $out->append($header_kv[$_])->append($_ & 1? "\n" : ": ");
      }
      $out->append("\n"); # empty line terminates headers
   }
   my $content_span= span($self->content);
   $content_span->append_to($out, encoding => BASE64);
   $out->append(($content_span->length? "\n" : '')
                .'-----END '.$self->label."-----\n");
   return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SecretBuffer::PEM - Parse PEM format from a SecretBuffer

=head1 SYNOPSIS

  use Crypt::SecretBuffer::PEM;
  my $secret= secret(load_file => "secrets.pem");
  my @pem= Crypt::SecretBuffer::PEM->parse_all($secret->span);

=head1 DESCRIPTION

This module parses the PEM format used by OpenSSL and OpenSSH.  PEM is a simple text format made
of a block of Base64 data with optional headers and begin/end markers.  This module parses the
begin/end markers, copies that span of bytes into a new SecretBuffer, makes the headers into
a hashref, and stores the Span of Base64 as the attribute L</content>.

To be clear, this only parses the I<text portions> of PEM, I<not the ASN.1 structure> within the
base64 data.

The label around the PEM block and its headers (if any) are considered non-secret, and copied
out of the SecretBuffer into perl scalars.  The Base64 payload remains inside the SecretBuffer,
in case this was an unencrypted private key.  There is also an option to treat the header values
as secrets.

=head1 CONSTRUCTORS

=head2 parse

  my $pem= Crypt::SecretBuffer::PEM->parse($span, %options);

Parse the next PEM block found in the L<Span|Crypt::SecretBuffer::Span>.  The span is updated to
begin on the line following the PEM block.  If no PEM block is found, this returns C<undef> and
the span object remains unchanged.

Invalid PEM blocks (such as mismatched BEGIN/END markers) are ignored, as well as any text
outside of the markers.

Options:

=over

=item secret_headers

Boolean, whether the values of the PEM headers should be stored in L<Crypt::SecretBuffer::Span>
objects.  Default is false.

=item trim_headers

Boolean.  The default is to trim leading and trailing whitespace from keys and values of the
headers.  You can set this to false to preserve that whitespace (but the space following ':'
always gets removed)

=back

=head2 parse_all

  my @pem_blocks= Crypt::SecretBuffer::PEM->parse_all($span, %options);

A file can contain more than one PEM block (such as a SSL certificate chain, and its key)
This just calls L</parse> in a loop until no more PEM blocks are found.

=head2 new

  my $pem= Crypt::SecretBuffer::PEM->new(%attributes);

You can construct a PEM object from attributes, in case you want to serialize your own data.

=head1 ATTRIBUTES

=head2 label

The text from the PEM begin-marker:

   -----BEGIN SOME LABEL-----
   ...
   -----END SOME LABEL-----

In this case the attribute would hold C<< 'SOME LABEL' >>.

=head2 buffer

A L<Crypt::SecretBuffer> holding the complete PEM text from BEGIN marker to END marker, inclusive.

=head2 header_kv

PEM format has optional header C<< 'NAME: VALUE' >> pairs that can appear right after the
BEGIN marker.  When parsed, leading and trailing whitespace are removed from keys and values.
When written, keys and values may not contain leading or trailing whitespace, or any control
characters.  This attribute presents them in their original order as an arrayref of
C<< [ $key0, $value0, $key1, $value1, ... ] >>.

Note that the values can be L<Span|Crypt::SecretBuffer::Span> objects if you used the
C<secret_headers> option.

=head2 headers

  my $values_arrayref= $pem->headers->get_values('example');
  my $value_maybe_arrayref= $pem->headers->{example};
  $pem->headers->{example}= $value;
  $pem->headers->append('example', $value);

For convenience, you can access the headers by name using this attribute, which masquerades as
L<both a hashref and an object with methods|Crypt::SecretBuffer::PEM::Headers>.
This object/hashref only provides a view of the L<header_kv> array, and is not particularly
efficient at reading or writing it.  (but, it's very convenient)

If there are multiple header keys with the same name, the value returned for that name is an
arrayref of all the values.

=head2 content

A L<Span|Crypt::SecretBuffer::Span> or SecretBuffer that contains the bytes of the PEM payload.
This span created by L</parse> has C<< encoding => BASE64 >> set, which affects the
character-based methods like C<parse>, but has not actually been Base64-decoded, which matters
for methods like C<length> or C<memcmp>.

=head1 METHODS

=head2 serialize

  $buffer= $pem->serialize;

This writes a PEM block into a SecretBuffer object.  The headers (if any) come from L</header_kv>,
falling back to the L</headers> hashref.

=head1 VERSION

version 0.019

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
