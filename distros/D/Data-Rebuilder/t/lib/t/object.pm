
package t::object;
use strict;
use warnings;

sub new { bless {}; }

sub car { @_ > 1 ? ($_[0]->{car} = $_[1]) :  $_[0]->{car} }
sub cdr { @_ > 1 ? ($_[0]->{cdr} = $_[1]) :  $_[0]->{cdr} }


sub extend {
  my $self = shift;
  my $cons = $self;
  while( $cons ){
    my $cdr = $cons->cdr;
    last unless $cdr;
    $cons = $cdr;
  }
  $cons->cdr( __PACKAGE__->new );
  $self;
}

sub length {
  my $self = shift;
  my $cdr = $self->cdr;
  return 1 unless $cdr;
  return 1 + $cdr->length;
}

1;
__END__
