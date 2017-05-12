package CAM::XML::XMLTree;

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

This is a modified copy of XML::Parser::Tree from XML/Parser.pm
v2.30.  It differs from the original in that each object is one
hashref instead of one scalar and one scalar/arrayref in the
object list.

=head1 FUNCTIONS

=over

=item Init()

=cut

sub Init
{
   my $expat = shift;
   $expat->{Stack}   = [];
   $expat->{Package} = 'CAM::XML';
   return;
}

=item Start($tag)

=cut

sub Start
{
   my $expat = shift;
   my $tag   = shift;

   my $obj   = $expat->{Package}->new($tag, @_);
   if (!$expat->{Base})
   {
      $expat->{Base} = $obj;
   }
   if (@{ $expat->{Stack} } > 0)
   {
      $expat->{Stack}->[-1]->add($obj);
   }
   push @{ $expat->{Stack} }, $obj;
   return;
}

=item End($tag)

=cut

sub End
{
   my $expat = shift;
   my $tag   = shift;
   pop @{ $expat->{Stack} };
   delete $expat->{Cdata};
   return;
}

=item Char($text)

=cut

sub Char
{
   my $expat = shift;
   my $text  = shift;

   $expat->{Stack}->[-1]
       ->add(($expat->{Cdata} ? '-cdata' : '-text') => $text);
   return;
}

=item CdataStart()

=cut

sub CdataStart
{
   my $expat = shift;
   $expat->{Cdata} = 1;
   return;
}

=item CdataEnd()

=cut

sub CdataEnd
{
   my $expat = shift;
   delete $expat->{Cdata};
   return;
}

=item Final()

=cut

sub Final
{
   my $expat = shift;
   delete $expat->{Stack};
   return delete $expat->{Base};
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary Developer: Chris Dolan

=cut
