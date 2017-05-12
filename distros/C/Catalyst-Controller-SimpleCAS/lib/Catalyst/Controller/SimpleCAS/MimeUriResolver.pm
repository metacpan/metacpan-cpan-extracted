package Catalyst::Controller::SimpleCAS::MimeUriResolver;
use Moose;

use strict;
use warnings;

use Try::Tiny;

use Email::MIME::CreateHTML::Resolver::LWP;

has 'Cas' => (
  is => 'ro',
  isa => 'Catalyst::Controller::SimpleCAS',
  required => 1
);

has 'Resolver' => (
  is => 'ro',
  isa => 'Object',
  lazy => 1,
  default => sub {
    my $self = shift;
    return Email::MIME::CreateHTML::Resolver::LWP->new({ base => $self->base });
  }
);

has 'base' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);


sub get_resource {
  my $self = shift;
  my ($uri) = @_;
  
  my ($content,$filename,$mimetype,$xfer_encoding);
  
  my $Content = $self->Cas->uri_find_Content($uri);
  if($Content) {
    $content = $Content->content;
    $filename = $Content->MIME->filename(1);
    $mimetype = $Content->MIME->content_type;
    $xfer_encoding = $Content->MIME->header('Content-Transfer-Encoding');
  }
  else {
    try {
      # TODO:
      # This will throw an exception if the url is relative:
      #    "Could not fetch <url> : 400 URL must be absolute"
      # Relative urls probably indicate it is a resource of the
      # local application; we should handle this case by setting
      # up a virtual/internal request. In the mean time, we 
      # are wrapping in a try block to avoid dumping the whole
      # request, so at least something can be returned, even if
      # it is missing some inline images, etc
      ($content,$filename,$mimetype,$xfer_encoding) = $self->Resolver->get_resource(@_);
    }
  }
  
  return ($content,$filename,$mimetype,$xfer_encoding);
}


1;

__END__

=head1 NAME

Catalyst::Controller::SimpleCAS::MimeUriResolver - Internal MIME resource resolver for SimpleCAS

=head1 SYNOPSIS

 use Catalyst::Controller::SimpleCAS;
 ...

=head1 DESCRIPTION

This class is used internally by L<Catalyst::Controller::SimpleCAS::Role::TextTranscode> and 
should not called/used directly.

=head1 ATTRIBUTES

=head2 Cas

=head2 Resolver

=head2 base

=head1 METHODS

=head2 get_resource

=head1 SEE ALSO

=over

=item *

L<Catalyst::Controller::SimpleCAS::Role::TextTranscode>

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