package CAM::PDF::Node;

use 5.006;
use warnings;
use strict;

our $VERSION = '1.60';

=head1 NAME

CAM::PDF::Node - PDF element

=head1 SYNOPSIS

   my $node = CAM::PDF::Node->new('number', 1.0);

=head1 DESCRIPTION

This is a simplistic internal class for representing arbitrary PDF
data structures.

=head1 LICENSE

Same as L<CAM::PDF>

=head1 FUNCTIONS

=over

=item $pkg->new($type, $value)

=item $pkg->new($type, $value, $objnum)

=item $pkg->new($type, $value, $objnum, $gennum)

Create a new PDF element.

=cut

sub new
{
   my $pkg = shift;

   my $self = {
      type => shift,
      value => shift,
   };

   my $objnum = shift;
   my $gennum = shift;
   if (defined $objnum)
   {
      $self->{objnum} = $objnum;
   }
   if (defined $gennum)
   {
      $self->{gennum} = $gennum;
   }

   return bless $self, $pkg;
}

1;
__END__

=back

=head1 AUTHOR

See L<CAM::PDF>

=cut
