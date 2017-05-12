# Content object class
package Catalyst::Controller::SimpleCAS::Content;
use Moose;

use Email::MIME;
use Image::Size;

has 'Store', is => 'ro', required => 1, isa => 'Object';
has 'checksum', is => 'ro', required => 1, isa => 'Str';
has 'filename', is => 'ro', isa => 'Maybe[Str]', default => undef;

sub BUILD {
  my $self = shift;
  die "Content does not exist" unless ($self->Store->content_exists($self->checksum));
}

has 'MIME' => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;

    my $attrs = {
      content_type => $self->mimetype,
      encoding => 'base64'
    };
    $attrs = { %$attrs, 
      filename => $self->filename,
      name => $self->filename
    } if ($self->filename);
  
    return Email::MIME->create(
      attributes => scalar $attrs,
      body       => scalar $self->content
    );

  }
);

has 'mimetype' => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    return $self->Store->content_mimetype($self->checksum);
  }
);

has 'image_size' => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my ($width,$height) = $self->Store->image_size($self->checksum);
    return [$width,$height];
  }
);


has 'size' => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    return $self->Store->content_size($self->checksum);
  }
);

# TODO: abstract this properly and put it in the right place
has 'fetch_url_path', is => 'ro', isa => 'Str', default => '/simplecas/fetch_content/';

has 'src_url', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $url = $self->fetch_url_path . $self->checksum;
  $url .= '/' . $self->filename if ($self->filename);
  return $url;
};

has 'file_ext', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return undef unless ($self->filename);
  my @parts = split(/\./,$self->filename);
  return undef unless (scalar @parts > 1);
  return lc(pop @parts);
};

has 'filelink_css_class', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my @css_class = ('filelink');
  push @css_class, $self->file_ext if ($self->file_ext);
  return join(' ',@css_class);
};

has 'filelink', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $name = $self->filename || $self->checksum;
  return '<a class="' . $self->filelink_css_class . '" ' .
    ' href="' . $self->src_url . '">' . $name . '</a>';
};

has 'img_size', is => 'ro', lazy => 1, default => sub {
  my $self = shift;

  my $content_type = $self->mimetype or return undef;
  my ($mime_type,$mime_subtype) = split(/\//,$content_type);
  return undef unless ($mime_type eq 'image');
  
  my ($width,$height) = imgsize($self->Store->checksum_to_path($self->checksum)) or return undef;
  #return ($width,$height);
  return { height => $height, width => $width };
};

has 'imglink', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return undef unless ($self->img_size);
  
  return '<img src="' . $self->src_url . '" ' .
    'height=' . $self->img_size->{height} . ' ' .
    'width=' . $self->img_size->{width} . ' ' .
  '>';
};

sub fh {
  my $self = shift;
  return $self->Store->fetch_content_fh($self->checksum);
}

sub content {
  my $self = shift;
  return $self->Store->fetch_content($self->checksum);
}

1;

__END__

=head1 NAME

Catalyst::Controller::SimpleCAS::Content - Content object class for SimpleCAS

=head1 SYNOPSIS

 use Catalyst::Controller::SimpleCAS;
 ...

=head1 DESCRIPTION

This object class is used to represent an individual content entity within a SimpleCAS Store.
This is used internally and is not meant to be called/used directly.

=head1 ATTRIBUTES

=head2 Store

=head2 checksum

=head2 filename

=head2 MIME

=head2 mimetype

=head2 image_size 

=head2 size 

=head2 fetch_url_path

=head2 src_url

=head2 file_ext

=head2 filelink_css_class

=head2 filelink

=head2 img_size

=head2 imglink


=head1 METHODS

=head2 content

=head2 fh

=head1 SEE ALSO

=over

=item *

L<Catalyst::Controller::SimpleCAS>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut