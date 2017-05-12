package CAM::XML::Text;

use warnings;
use strict;

our $VERSION = '1.14';

=head1 NAME 

CAM::XML::Text - XML text nodes

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

This is a helper class to hold text data

=head1 FUNCTIONS

=over

=item $pkg->new($type, $text)

=cut

sub new
{
   my $pkg  = shift;
   my $type = shift || 'none';
   my $text = shift;

   if (!defined $text)
   {
      $text = q{};
   }
   return bless {
      type => $type,
      text => $text,
   }, $pkg;
}

=item $self->toString()

=cut

sub toString
{
   my $self = shift;
   return $self->{type} eq 'text'  ? CAM::XML->_XML_escape($self->{text})    ##no critic for use of private sub
        : $self->{type} eq 'cdata' ? CAM::XML->_CDATA_escape($self->{text})  ##no critic for use of private sub
        : $self->{text};
}

=item $self->getInnerText()

=cut

sub getInnerText
{
   my $self = shift;
   return $self->{text};
}

sub _get_path_nodes
{
   my $self = shift;
   my $path = shift;

   return $path ? () : ($self);
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary Developer: Chris Dolan

=cut
