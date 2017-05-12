use strict;
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Fitness::Royal_Road - Mitchell's Royal Road function

=head1 SYNOPSIS

    my $block_size = 4;
    my $rr = Algorithm::Evolutionary::Fitness::Royal_Road->new( $block_size ); 

=head1 DESCRIPTION

Royal Road function, adds block_size to fitness only when the block is complete

=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::Royal_Road;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ ) ;

use base qw(Algorithm::Evolutionary::Fitness::String);

=head2 new( $block_size )

Creates a new instance of the problem, with the said block size. 

=cut 

sub new {
  my $class = shift;
  my ( $block_size ) = @_;
  my $self = $class->SUPER::new();
  $self->{'_block_size'} = $block_size;
  $self->initialize();
  return $self;
}

sub _really_apply {
    my $self = shift;
    return  $self->royal_road( @_ );
}

=head2 royal_road( $string )

Computes the royal road function with given block size. Results are
cached by default.

=cut

sub royal_road {
    my $self = shift;
    my $string = shift;
    my $cache = $self->{'_cache'};
    
    if ( $cache->{$string} ) {
	return $cache->{$string};
    }

    my $fitness = 0;
    my $block_size = $self->{'_block_size'};
    for ( my $i = 0; $i < length( $string ) / $block_size; $i++ ) {
	my $block = 0;
	if ( length( substr( $string, $i*$block_size, $block_size )) == $block_size ) {
	    $block=1;
	    for ( my $j = 0; $j < $block_size; $j++ ) {
		$block &= substr( $string, $i*$block_size+$j, 1 );
	    }
	}
	( $fitness += $block_size ) if $block;
    }
    $cache->{$string} = $fitness;
    return $cache->{$string};

}


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"What???";
