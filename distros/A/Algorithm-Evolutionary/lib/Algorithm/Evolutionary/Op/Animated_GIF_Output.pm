package Algorithm::Evolutionary::Op::Animated_GIF_Output;

use lib qw( ../../../../lib 
	    ../../../lib
	    ../../../../../../Algorithm-Evolutionary/lib ../Algorithm-Evolutionary/lib ); #For development and perl syntax mode

use warnings;
use strict;
use Carp;

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::Evolutionary::Op::Base';

use GD::Image;

sub new {
  my $class = shift;
  my $hash = shift || croak "No default values for length ";
  my $self = Algorithm::Evolutionary::Op::Base::new( __PACKAGE__, 1, $hash );
  $hash->{'pixels_per_bit'} = $hash->{'pixels_per_bit'} || 1;
  $self->{'_image'} = GD::Image->new($hash->{'length'}*$hash->{'pixels_per_bit'},
				     $hash->{'number_of_strings'}*$hash->{'pixels_per_bit'});
  $self->{'_length'} = $hash->{'length'};
  $self->{'_pixels_per_bit'} = $hash->{'pixels_per_bit'};
  $self->{'_white'} = $self->{'_image'}->colorAllocate(0,0,0); #background color
  $self->{'_black'} = $self->{'_image'}->colorAllocate(255,255,255);
  $self->{'_gifdata'} = $self->{'_image'}->gifanimbegin;
  $self->{'_gifdata'}   .= $self->{'_image'}->gifanimadd;    # first frame
  return $self;
}


sub apply {
    my $self = shift;
    my $population_hashref=shift;
    my $frame  = GD::Image->new($self->{'_image'}->getBounds);
    my $ppb = $self->{'_pixels_per_bit'};
    my $l=0;
    for my $i (@$population_hashref) {
      my $bit_string = $i->{'_str'};
      for my $c ( 0..($self->{'_length'}-1) ) {
	my $bit = substr( $bit_string, $c, 1 );
	if ( $bit ) {
	  for my $p ( 1..$ppb ) {
	    for my $q (1..$ppb ) {
	      $frame->setPixel($l*$ppb+$q, $c*$ppb+$p,
			       $self->{'_black'})
	    }
	  }
	}
      }
      $l++;
    }
    $self->{'_gifdata'}   .= $frame->gifanimadd;     # add frame
}

sub terminate {
  my $self= shift;
  $self->{'_gifdata'}   .= $self->{'_image'}->gifanimend;
}

sub output {
  my $self = shift;
  return $self->{'_gifdata'};
}

"No man's land" ; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::Evolutionary::Op::Animated_GIF_Output - Creates an animated GIF, a frame per generation. Useful for binary strings.


=head1 SYNOPSIS

  my $pp = new Algorithm::Evolutionary::Op::Animated_GIF_Output; 

  my @pop;
  my $length = 8;
  my $number_of_strings = 10;
  for ( 1..$number_of_strings ) {
    my $indi= new Algorithm::Evolutionary::Individual::String [0,1], $length;
    push @pop, $indi;
  }

  $pp->apply( \@pop );
  my $options = { pixels_per_bit => 2,
                  length => $length,
                  number_of_strings => $number_of_strings };

  $pp = new Algorithm::Evolutionary::Op::Animated_GIF_Output $options

  $pp->apply( \@pop );
  $pp->terminate();
  my $output_gif = $pp->output(); # Prints final results

=head1 DESCRIPTION

Saves each generation as a frame in an animated GIF. Every individual
gets a line of the number of pixels specified, and bits set to "1" are
represented via black pixels or fat pixels. By default, a bit takes a
single pixel. 

=head1 INTERFACE 

=head2 new( [$hash_ref] )

C<$hash_ref> is a hashref with 3 options: C<pixels_per_bit>, which
defaults to 1, and C<length> and C<number_of_strings> which have no
default and need to be set in advance to set up the GIF before any
population individual is seen.

=head2 apply( $population_hashref )

Applies the single-member printing function to every population member

=head2 terminate()

Finish the setup of the animated GIF.

=head2 output()

Returns the animaged GIF; must be assigned to a variable.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-algorithm-evolutionary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights
reserved. 

This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/12/19 21:39:12 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Animated_GIF_Output.pm,v 1.5 2010/12/19 21:39:12 jmerelo Exp $ 
  $Author: jmerelo $ 

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
