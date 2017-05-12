package Data::Transform::Zlib;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Compress::Raw::Zlib qw(Z_OK Z_STREAM_END Z_FINISH Z_SYNC_FLUSH);

use base qw(Data::Transform);

our $VERSION = '0.02';

=head1 NAME

Data::Transform::Zlib - A Filter for RFC195[0-2]

=head1 DESCRIPTION

Data::Transform::Zlib provides a filter for performing (de-)compression
using L<Compress::Raw::Zlib>. Since it is just a wrapper around that
module, it supports the same features.

=head1 METHODS

Data::Transform::Zlib implements the standard Data::Transform API. Only
additions and differences are documented here.

=cut

sub BUFFER          () { 0 }
sub DEFLATER        () { 1 }
sub DEFLATE_OPTIONS () { 2 }
sub INFLATER        () { 3 }
sub INFLATE_OPTIONS () { 4 }

=head2 new

new() creates a new object. It accepts the following named parameters:

=over 2

=item inflate

A hashref containing parameters suitable to pass to Compress::Raw::Zlib::Inflate().

=item deflate

A hashref containing parameters suitable to pass to Compress::Raw::Zlib::Deflate().

=back

The only really interesting thing to set here is -WindowBits. If you
set it to WANT_GZIP (symbol exported by Compress::Raw::Zlib), it will
use gzip compression instead of zlib.

See the L<Compress::Raw::Zlib> documentation for more details.

=cut

sub new {
  my $type = shift;

   my $self = [
      [],
   ];

  croak "$type requires an even number of parameters" if @_ % 2;
  my %param = @_;

   my $deflate_options = $self->[DEFLATE_OPTIONS] = $param{deflate} || {};
   $self->[DEFLATER] = Compress::Raw::Zlib::Deflate->new(%$deflate_options)
      or croak "Couldn't create deflater object";
   my $inflate_options = $self->[INFLATE_OPTIONS] = $param{inflate} || {};
   $self->[INFLATER] = Compress::Raw::Zlib::Inflate->new(%$inflate_options)
      or croak "Couldn't create inflater object";

   return bless $self, $type;
}

sub clone {
   my $self = shift;
   my $deflate_options = $self->[DEFLATE_OPTIONS];
   my $deflater = Compress::Raw::Zlib::Deflate->new( %$deflate_options );
   my $inflate_options = $self->[INFLATE_OPTIONS];
   my $inflater = Compress::Raw::Zlib::Inflate->new( %$inflate_options );
   my $nself = [
      [],
      $deflater,
      $deflate_options,
      $inflater,
      $inflate_options,
  ];
  return bless $nself, ref $self;
}

sub _handle_get_data {
   my ($self, $data) = @_;

   return unless $data;

   my $out;
   my $status = $self->[INFLATER]->inflate($data, $out);
   unless ($status == Z_OK or $status == Z_STREAM_END) {
      return Data::Transform::Meta::Error->new(
            "Couldn\'t inflate buffer ($status)"
         );
   }
   if ($status == Z_STREAM_END) {
    $self->[INFLATER] = Compress::Raw::Zlib::Inflate->new(%{ $self->[INFLATE_OPTIONS]});
  }
  return $out if $out;
  return;
}

sub _handle_put_meta {
   my ($self, $meta) = @_;
   my ($type, @ret);
   $type = Z_FINISH     if ($meta->isa('Data::Transform::Meta::EOF'));
   $type = Z_SYNC_FLUSH if (defined $meta->data and $meta->data eq 'sync');
   if (defined $type) {
      my ($fout,$fstat);
      $fstat = $self->[DEFLATER]->flush($fout, $type);
      push (@ret, $fout);
      unless ( $fstat == Z_OK ) {
         warn "Error flushing data ($fstat)";
      }
      if ($type == Z_FINISH) {
         $self->[DEFLATER] = Compress::Raw::Zlib::Deflate->new(
            %{$self->[DEFLATE_OPTIONS]}
            );
      }
   }
   push @ret, $meta;
   return @ret;
}

sub _handle_put_data {
  my ($self, $data) = @_;

   my ($dstat, $dout);
   $dstat = $self->[DEFLATER]->deflate($data, $dout);
   unless ($dstat == Z_OK) {
      warn "Error deflating data ($dstat)";
   }
   return $dout;
}

1;

=head1 METADATA

Due to how the zlib protocol works, it is important that you don't forget
to close the stream by sending a L<Data::Transform::Meta::EOF> packet when
you're writing data. Otherwise the filter might be holding back data while
waiting to see if additional data may help compression.

In case you're using this in a request/response protocol like XMPP (with
stream compression enabled), you will also have to send a
L<Data::Transform::Meta> packet with the string "sync" as the content after
each request/response. This makes the filter flush what is in its buffer,
so you can be sure your request or response gets sent out. Otherwise,
the filter might be waiting for more input to see whether it can compress
the data even better, while you need the packet sent so you can get an
answer from the remote side.

=head1 AUTHOR

Data::Transform::Zlib was adapted from the POE::Filter::Zlib filter
which was written by Chris Williams <chris@bingosnet.co.uk>

Martijn van Beers <martijn@cpan.org> did the adapting and maintains it.

=head1 LICENSE

Copyright C<(c)> Chris Williams and Martijn van Beers.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU GPL, version 3.0 or higher.

=head1 SEE ALSO

L<Data::Transform>

L<Compress::Raw::Zlib>

=cut

