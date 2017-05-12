package CAM::PDF::Renderer::TextFB;

use 5.006;
use warnings;
use strict;
use CAM::PDF;

our $VERSION = '1.60';

=for stopwords framebuffer

=head1 NAME

CAM::PDF::Renderer::TextFB - Framebuffer for CAM::PDF::Renderer::Text

=head1 LICENSE

See CAM::PDF.

=head1 SYNOPSIS

See CAM::PDF::Renderer::Text.

=head1 DESCRIPTION

This class is used solely to assist CAM::PDF::Renderer::Text.

=head1 FUNCTIONS

=over

=item $pkg->new(width, height)

Creates a new framebuffer.

=cut

sub new
{
   my $pkg = shift;
   my $w = shift;
   my $h = shift;

   my $self = bless {
      w => $w,
      h => $h,
      fb =>[],
   }, $pkg;
   for my $r (0 .. $h-1)
   {
      $self->{fb}->[$r] = [(q{})x$w];
   }
   return $self;
}

=item $self->add_string($x, $y, $string)

Renders a string on the framebuffer.

=cut

sub add_string
{
   my $self = shift;
   my $x = shift;
   my $y = shift;
   my $string = shift;

   CAM::PDF->asciify(\$string);

   my $fb = $self->{fb};
   if (defined $fb->[$y])
   {
      if (defined $fb->[$y]->[$x])
      {
         $fb->[$y]->[$x] .= $string;
      }
      else
      {
         #print "bad 1\n";
         $fb->[$y]->[$x] = $string;
      }
   }
   else
   {
      #print "bad 2\n";
      $fb->[$y] = [];
      $fb->[$y]->[$x] = $string;
   }
   return;
}

=item $self->toString()

Serializes the framebuffer into a single string that can be easily printed.

=cut

sub toString
{
   my $self = shift;

   my @str;
   my $fb = $self->{fb};
   for my $r (reverse 0 .. $#{$fb})   # PDF is bottom to top, we want top to bottom
   {
      my $row = $fb->[$r];
      if ($row)
      {
         #print "r $r c ".@$row."\n";
         #print '>';
         for my $c (0 .. $#{$row})
         {
            my $str = $row->[$c];
            if (!defined $str || $str eq q{})
            {
               $str = q{ };
            }
            push @str, $str;
         }
      }
      else
      {
         #print "r $r c 0\n";
         #print '>';
      }
      push @str, "\n";
   }
   return join q{}, @str;
}

1;
__END__

=back

=head1 AUTHOR

See L<CAM::PDF>

=cut
