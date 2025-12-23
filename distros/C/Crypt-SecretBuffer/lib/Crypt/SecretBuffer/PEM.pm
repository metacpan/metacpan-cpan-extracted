package Crypt::SecretBuffer::PEM;
# VERSION
# ABSTRACT: Parse PEM format from a SecretBuffer
$Crypt::SecretBuffer::PEM::VERSION = '0.015';
use strict;
use warnings;
use Carp;
use Scalar::Util qw( blessed );
use Crypt::SecretBuffer qw/ secret MATCH_NEGATE MATCH_MULTI ISO8859_1 BASE64 /;


sub parse {
   my ($class, $span)= @_;
   while (my $begin= $span->scan("-----BEGIN ")) {
      $span->pos($begin->lim);
      my $label= $span->parse(qr/[A-Z0-9 ]+/);
      next unless $label && $span->parse("-----\n");
      $begin->lim($span->pos);
      my $label_str= '';
      $label->copy_to($label_str);
      my $end= $span->scan("-----END $label_str-----");
      unless ($end) {
         warn "PEM begin marker for $label_str lacks an END marker";
         next;
      }
      $span->pos($end->lim);
      $span->parse("\r");
      $span->parse("\n"); # consume line ending

      # Let block be its own SecretBuffer
      my $block= $span->clone(pos => $begin->pos, lim => $span->pos)->copy;
      my $inner= $block->span(pos => $begin->len, lim => $end->pos - $begin->pos);
      if (!$block->span($end->pos - $begin->pos - 1, 1)->ends_with("\n")) {
         warn "PEM end marker found not at the start of a line";
         next;
      }
      # Treat each line containing a ":" as a "name: value" header
      my @headers;
      while (my $sep_or_eol= $inner->scan(qr/[:\n]/)) {
         if ($sep_or_eol->starts_with(':')) {
            my $name;
            $inner->clone(lim => $sep_or_eol->pos)->copy_to($name);
            $inner->pos($sep_or_eol->lim);
            my $eol= $inner->scan("\n") or die "BUG"; # inner ends with "\n", checked above
            my $value= $inner->clone(lim => $eol->pos);
            $value->ltrim(' '); # remove one optional space character
            $inner->pos($eol->lim);
            push @headers, $name, $value;
         }
         else {
            # If any headers were found, there needs to be a blank line
            if (@headers) {
               if ($sep_or_eol->pos == $inner->pos) { # "\n" at start of 'inner'
                  $inner->pos($sep_or_eol->lim);
               } else {
                  warn "PEM headers for $label_str did not end with a blank line"
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
   my ($class, $span)= @_;
   my @pem;
   while (my $pem= $class->parse($span)) {
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


sub buffer    { $_[0]{buffer}=    $_[1] if @_ > 1; $_[0]{buffer} }
sub label     { $_[0]{label}=     $_[1] if @_ > 1; $_[0]{label} }
sub headers   { $_[0]{headers}=   $_[1] if @_ > 1; $_[0]{headers} ||= $_[0]->_build_headers }
sub header_kv { $_[0]{header_kv}= $_[1] if @_ > 1; $_[0]{header_kv} }
sub content   { $_[0]{content}=   $_[1] if @_ > 1; $_[0]{content} }

sub _build_headers {
   return { @{$_[0]{header_kv}} };
}


sub serialize {
   my $self= shift;
   my $out= secret('-----BEGIN '.$self->label."-----\n");
   my @header_kv= $self->header_kv? @{ $self->header_kv }
                : $self->headers? %{ $self->headers }
                : ();
   if (@header_kv) {
      while (@header_kv) {
         my ($k, $v)= splice @header_kv, 0, 2;
         # Sanity checks, key cannot contain control chars or :
         croak "PEM Header name cannot contain ':' or control characters"
            if $k =~ /[\0-\x1F:]/;
         croak "PEM value cannot contain newline"
            if blessed($v) && $v->can('scan')? $v->scan("\n") : $v =~ /\n/;
         $out->append("$k: ")->append($v)->append("\n");
      }
      $out->append("\n"); # empty line terminates headers
   }
   if ($self->content->encoding == BASE64) {
      $out->append($self->content);
   } else {
      $out->append($self->content->copy(encoding => BASE64));
   }
   $out->append('-----END '.$self->label."-----\n");
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
begin/end markers, copies that span of bytes into a new SecretBuffer, makes the attributes into
a hash, and marks the Base64 span in case you want to process the bytes.

To be clear, this only parses the I<text portions> of PEM, I<not the ASN.1 structure> within the
base64 data.

The label around the PEM block and the keys of its headers (if any) are considered non-secret,
and copied out of the SecretBuffer into perl scalars.  The values of the headers, and the Base64
payload remain inside secret Span objects.

=head1 CONSTRUCTORS

=head2 parse

  my $pem= Crypt::SecretBuffer::PEM->parse($span);

Parse the next PEM block found in the L<Span|Crypt::SecretBuffer::Span>.  The span is updated to
begin on the line following the PEM block.  If no PEM block is found, the span object remains
unchanged.

Invalid PEM blocks (such as mismatched BEGIN/END markers) are ignored, as well as any text
outside of the markers.

=head2 parse_all

  my @pem_blocks= Crypt::SecretBuffer::PEM->parse_all($span);

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

=head2 headers

PEM format has optional C<< 'NAME: VALUE' >> pairs that can appear right after the BEGIN marker.
This presents them as a hashref.  Note that the values are L<Span|Crypt::SecretBuffer::Span>
objects.

=head2 header_kv

To preserve order of headers, this attribute stores a list of C<< [ $key, $value, ... ] >>.
Note that the values are L<Span|Crypt::SecretBuffer::Span> objects.

=head2 content

A L<Span|Crypt::SecretBuffer::Span> or SecretBuffer that contains the bytes of the PEM payload.

=head1 METHODS

=head2 serialize

  $buffer= $pem->serialize;

This writes a PEM block into a SecretBuffer object.  The headers (if any) come from L</header_kv>,
falling back to the L</headers> hashref.

=head1 VERSION

version 0.015

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
