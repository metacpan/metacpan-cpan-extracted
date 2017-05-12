package Catalyst::Controller::SimpleCAS::Store;

use strict;
use Moose::Role;

use Digest::SHA1;
use IO::File;
use MIME::Base64;
use Try::Tiny;
use File::MimeInfo::Magic;
use Image::Size;
use Email::MIME;
use IO::All;
use Path::Class qw( file dir );

requires qw(
  content_exists
  fetch_content
  add_content
  checksum_to_path
);

sub add_content_base64 {
  my $self = shift;
  my $data = decode_base64(shift) or die "Error decoding base64 data. $@";
  return $self->add_content($data);
}

sub add_content_file {
  my $self = shift;
  my $file = shift;

  my $checksum = $self->file_checksum($file);

  return $checksum if ($self->content_exists($checksum));

  return $self->add_content(scalar(io($file)->slurp));
}

sub add_content_file_mv {
  my $self = shift;
  my $file = shift;

  my $result = $self->add_content_file($file);

  die "SimpleCAS: Failed to move file '$file' into storage" unless $result;

  unlink $file;
  
  return $result;
}

sub image_size {
  my $self = shift;
  my $checksum = shift;
  
  my $content_type = $self->content_mimetype($checksum) or return undef;
  my ($mime_type,$mime_subtype) = split(/\//,$content_type);
  return undef unless ($mime_type eq 'image');
  
  my ($width,$height) = imgsize($self->checksum_to_path($checksum)) or return undef;
  return ($width,$height);
}

sub content_mimetype {
  my $self = shift;
  my $checksum = shift;
  
  # See if this is an actual MIME file with a defined Content-Type:
  my $MIME = try{
    my $fh = $self->fetch_content_fh($checksum);
    # only read the begining of the file, enough to make it past the Content-Type header:
    my $buf; $fh->read($buf,1024); $fh->close;
    
    # This will frequently produce uninitialized value warnings from Email::Simple::Header,
    # and I haven't been able to figure out how to stop it
    return Email::MIME->new($buf);
  };
  if($MIME && $MIME->content_type) {
    my ($type) = split(/\s*\;\s*/,$MIME->content_type);
    return $type;
  }

  # Otherwise, guess the mimetype from the file on disk
  my $file = $self->checksum_to_path($checksum);

  return undef unless ( -f $file );
  return mimetype($file);
}

sub content_size {
  my $self = shift;
  my $checksum = shift;
  
  my $file = $self->checksum_to_path($checksum);
  
  return file($file)->stat->size;
}

sub fetch_content_fh {
  my $self = shift;
  my $checksum = shift;

  my $file = $self->checksum_to_path($checksum);
  return undef unless ( -f $file);
  
  my $fh = IO::File->new();
  $fh->open($file, '<:raw') or die "Failed to open $file for reading.";
  
  return $fh;
}

# All stores should use SHA-1, in order to be able to swap Store modules later on.
sub file_checksum {
  my $self = shift;
  my $file = shift;
  
  my $FH = IO::File->new();
  $FH->open($file, '<:raw') or die "$! : $file\n";

  my $sha1 = Digest::SHA1->new->addfile($FH)->hexdigest;
  $FH->close;
  return $sha1;
}

sub calculate_checksum {
  my $self = shift;
  my $data = shift;
  
  my $sha1 = Digest::SHA1->new->add($data)->hexdigest;
  return $sha1;
}

1;

=head1 NAME

Catalyst::Controller::SimpleCAS::Store - Base Role for all SimpleCAS Store

=head1 SYNOPSIS

=head1 DESCRIPTION

Used as role for all storages of SimpleCAS.

=head1 METHODS

=head2 add_content

=head2 add_content_base64

=head2 add_content_file

=head2 add_content_file_mv

=head2 calculate_checksum

=head2 checksum_to_path

=head2 content_exists

=head2 content_mimetype

=head2 content_size

=head2 fetch_content

=head2 fetch_content_fh

=head2 file_checksum

=head2 image_size

=head2 init_store_dir

=head2 split_checksum

=head1 SEE ALSO

=over

=item *

L<Catalyst::Controller::SimpleCAS>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
