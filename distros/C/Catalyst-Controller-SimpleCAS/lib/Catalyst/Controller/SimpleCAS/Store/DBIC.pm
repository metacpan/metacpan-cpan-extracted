package Catalyst::Controller::SimpleCAS::Store::DBIC;

use warnings;
use Moose;

with qw(
  Catalyst::Controller::SimpleCAS::Store
);

use File::MimeInfo::Magic;
use Image::Size;
use Digest::SHA1;
use IO::File;
use Data::Dumper;
use MIME::Base64;
use Try::Tiny;
use Path::Class qw( file dir );

use IO::All;

use bytes;

has 'model' => ( is => 'ro', isa => 'Str', required => 1 );
has 'tempdir' => ( is => 'ro', isa => 'Str', lazy => 1, default => sub {
  my $self = shift;
  return dir( Catalyst::Utils::class2tempdir($self->resultset->result_class), 'simplecas' )->stringify;
});

sub resultset {
  my ( $self ) = @_;
  $self->simplecas->_app->model($self->model);
}

sub get_result_by_checksum {
  my ( $self, $checksum ) = @_;
  return $self->resultset->find({
    checksum => $checksum,
  });
}

sub add_content {
  my ( $self, $data ) = @_;
  my $checksum = $self->calculate_checksum($data);
  return $checksum if ($self->content_exists($checksum));
  my $size = length($data);
  my $result = $self->resultset->create({
    content => $data,
    checksum => $self->calculate_checksum($data),
    size => $size,
  });
  die "Unable to store data of $size bytes in Storage" unless $result;
  return $result->checksum;
}

sub checksum_to_path {
  my ( $self, $checksum ) = @_;
  my @parts = unpack("(A5)*", $checksum);
  my $filename = pop @parts;
  my $dir = join("/",$self->tempdir,@parts);
  my $fullname = join("/",$dir,$filename);
  return $fullname if io($fullname)->exists; 
  io($dir)->mkpath;
  my $entry = $self->get_result_by_checksum($checksum);
  io($fullname)->print($entry->content);
  return $fullname;
}

sub fetch_content {
  my ( $self, $checksum ) = @_;
  my $entry = $self->get_result_by_checksum($checksum);
  return "" unless $entry;
  return $entry->content;
}

sub content_exists {
  my ( $self, $checksum ) = @_;
  return $self->get_result_by_checksum($checksum) ? 1 : 0;
}

around content_mimetype => sub {
  my $orig = shift;
  my $self = shift;
  my $checksum = shift;
  my $result = $self->get_result_by_checksum($checksum);
  return undef unless $result;
  return $result->mimetype if defined $result->mimetype;
  my $mimetype = $self->$orig($checksum) || '';
  $result->mimetype($mimetype);
  $result->update;
  return $mimetype;
};

around image_size => sub {
  my $orig = shift;
  my $self = shift;
  my $checksum = shift;
  my $result = $self->get_result_by_checksum($checksum);
  return unless $result;
  if (defined $result->image_width) {
    return undef unless $result->image_width;
    return ( $result->image_width, $result->image_height );
  }
  my ( $width, $height ) = $self->$orig($checksum);
  $width = 0 unless $width;
  $height = 0 unless $height;
  $result->image_width($width);
  $result->image_height($height);
  $result->update;
  return undef unless $width;
  return ( $width, $height );
};

sub content_size {
  my ( $self, $checksum ) = @_;
  my $result = $self->get_result_by_checksum($checksum);
  return $result ? $result->size : 0;
}

#### --------------------- ####

no Moose;
#__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Catalyst::Controller::SimpleCAS::Store::DBIC - DBIx::Class Store for SimpleCAS

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 resultset

The actual L<DBIx::Class> ResultSet that should be used for all storage
activity.

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

=head2 get_result_by_checksum

=head1 SEE ALSO

=over

=item *

L<Catalyst::Controller::SimpleCAS>

=back

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut