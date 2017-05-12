package AI::NeuralNet::Kohonen::Demo::RGB;

use vars qw/$VERSION/;
$VERSION = 0.123;	# 13 March 2003; using smoothing

=head1 NAME

AI::NeuralNet::Kohonen::Demo::RGB - Colour-based demo

=head1 SYNOPSIS

	use AI::NeuralNet::Kohonen::Demo::RGB;
	$_ = AI::NeuralNet::Kohonen::Demo::RGB->new(
		display_scale => 20,
		display	=> 'hex',
		map_dim	=> 39,
		epochs  => 9,
		table   => "R G B"
	              ."1 0 0"
	              ."0 1 0"
	              ."0 0 1",
	);
	$_->train;
	exit;


=head1 DESCRIPTION

A sub-class of C<AI::NeuralNet::Kohonen>
that impliments extra methods to make use of TK
in a very slow demonstration of how a SOM can collapse
a three dimensional space (RGB colour values) into a
two dimensional space (the display). See L<SYNOPSIS>.

The only things added are two new fields to supply to the
constructor - set C<display> to C<hex> for display as
a unified distance matrix, rather than plain grid; set
C<display_scale> for the size of the display.

=cut

use strict;
use warnings;
use Carp qw/cluck carp confess croak/;

use base "AI::NeuralNet::Kohonen";

use Tk;
use Tk::Canvas;
use Tk::Label;
use Tk qw/DoOneEvent DONT_WAIT/;

#
# Used only by &tk_train
#
sub tk_show { my $self=shift;
	for my $x (0..$self->{map_dim_x}){
		for my $y (0..$self->{map_dim_y}){
			my $colour = sprintf("#%02x%02x%02x",
				(int (255 * $self->{map}->[$x]->[$y]->{weight}->[0])),
				(int (255 * $self->{map}->[$x]->[$y]->{weight}->[1])),
				(int (255 * $self->{map}->[$x]->[$y]->{weight}->[2])),
			);
			if ($self->{display} and $self->{display} eq 'hex'){
				my $xo = ($y % 2) * ($self->{display_scale}/2);
				my $yo = 0;

				$self->{c}->create(
					polygon	=> [
						$xo + ((1+$x)*$self->{display_scale} ),
						$yo + ((1+$y)*$self->{display_scale} ),

						# polygon only:
						$xo + ((1+$x)*($self->{display_scale})+($self->{display_scale}/2) ),
						$yo + ((1+$y)*($self->{display_scale})-($self->{display_scale}/2) ),
						#

						$xo + ((1+$x)*($self->{display_scale})+$self->{display_scale} ),
						$yo + ((1+$y)*$self->{display_scale} ),

						$xo + ((1+$x)*($self->{display_scale})+$self->{display_scale} ),
						$yo + ((1+$y)*($self->{display_scale})+($self->{display_scale}/2) ),

						# Polygon only:
						$xo + ((1+$x)*($self->{display_scale})+($self->{display_scale}/2) ),
						$yo + ((1+$y)*($self->{display_scale})+($self->{display_scale}) ),
						#

						$xo + ((1+$x)*$self->{display_scale} ),
						$yo + ((1+$y)*($self->{display_scale})+($self->{display_scale}/2) ),

					],
					-outline	=> "black",
					-fill 		=> $colour,
				);
			}
			else {
				$self->{c}->create(
					rectangle	=> [
						(1+$x)*$self->{display_scale} ,
						(1+$y)*$self->{display_scale} ,
						(1+$x)*($self->{display_scale})+$self->{display_scale} ,
						(1+$y)*($self->{display_scale})+$self->{display_scale}
					],
					-outline	=> "black",
					-fill 		=> $colour,
				);
			}
		}
	}
	return 1;
}


=head1 METHOD train

Over-rides the base class to provide TK displays of the map

=cut

sub train { my ($self,$epochs) = (shift,shift);
	my $label_txt;

	$epochs = $self->{epochs} unless defined $epochs;
	$self->{display_scale} = 10 if not defined 	$self->{display_scale};

	$self->{mw} = MainWindow->new(
		-width	=> 200+($self->{map_dim_x} * $self->{display_scale}),
		-height	=> 200+($self->{map_dim_y} * $self->{display_scale}),
	);
    my $quit_flag = 0;
    my $quit_code = sub {$quit_flag = 1};
    $self->{mw}->protocol('WM_DELETE_WINDOW' => $quit_code);

	$self->{c} = $self->{mw}->Canvas(
		-width	=> 50+($self->{map_dim_x} * $self->{display_scale}),
		-height	=> 50+($self->{map_dim_y} * $self->{display_scale}),
		-relief	=> 'ridge',
		-border => 5,
	);
	$self->{c}->pack(-side=>'top');

	my $l = $self->{mw}->Label(-text => ' ',-textvariable=>\$label_txt);
	$l->pack(-side=>'left');

	# Replaces Tk's MainLoop
    for (0..$self->{epochs}) {
		if ($quit_flag) {
			$self->{mw}->destroy;
			return;
		}
		$self->{t}++;				# Measure epoch
		my $target = $self->_select_target;
		my $bmu = $self->find_bmu($target);

		$self->_adjust_neighbours_of($bmu,$target);
		$self->_decay_learning_rate;

		$self->tk_show;
		$label_txt = sprintf("Epoch: %04d",$self->{t})."  "
		. "Learning: $self->{l}  "
		. sprintf("BMU: %02d,%02d",$bmu->[1],$bmu->[2])."  "
		. "Target: [".join(",",@$target)."]  "
		;
		$self->{c}->update;
		$l->update;
        DoOneEvent(DONT_WAIT);		# be kind and process XEvents if they arise
	}
	$label_txt = "Did $self->{t} epochs: now smoothed by "
		.($self->{smoothing}? $self->{smoothing} : "default amount");
	$_->smooth;
#	MainLoop;

	return 1;
}



1;

__END__

=head1 SEE ALSO

See
L<AI::NeuralNet::Kohonen>;
L<AI::NeuralNet::Kohonen::Node>;

=head1 AUTHOR AND COYRIGHT

This implimentation Copyright (C) Lee Goddard, 2003.
All Rights Reserved.

Available under the same terms as Perl itself.
















