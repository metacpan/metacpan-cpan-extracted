package AI::NeuralNet::Kohonen::Visual;

use vars qw/$VERSION/;
$VERSION = 0.3; # 05 May 2006 pod and packaging

=head1 NAME

AI::NeuralNet::Kohonen::Visual - Tk-based Visualisation

=head1 SYNOPSIS

Test the test file in this distribution, or:

	package YourClass;
	use base "AI::NeuralNet::Kohonen::Visual";

	sub get_colour_for { my ($self,$x,$y) = (shift,shift,shift);
		# From here you return a TK colour name.
		# Get it as you please; for example, values of a 3D map:
		return sprintf("#%02x%02x%02x",
			(int (255 * $self->{map}->[$x]->[$y]->{weight}->[0])),
			(int (255 * $self->{map}->[$x]->[$y]->{weight}->[1])),
			(int (255 * $self->{map}->[$x]->[$y]->{weight}->[2])),
		);
	}

	exit;
	1;

And then:

	use YourClass;
	my $net = AI::NeuralNet::Kohonen::Visual->new(
		display          => 'hex',
		map_dim          => 39,
		epochs           => 19,
		neighbour_factor => 2,
		targeting        => 1,
		table            => "3
			1 0 0 red
			0 1 0 yellow
			0 0 1 blue
			0 1 1 cyan
			1 1 0 yellow
			1 .5 0 orange
			1 .5 1 pink",
	);
	$net->train;
	$net->plot_map;
	$net->main_loop;

	exit;


=head1 DESCRIPTION

Provides TK-based visualisation routines for C<AI::NueralNet::Kohonen>.
Replaces the earlier C<AI::NeuralNet::Kohonen::Demo::RGB>.

This is a sub-class of C<AI::NeuralNet::Kohonen>
that impliments extra methods to make use of TK.

This moudle is itself intended to be sub-classed by you,
where you provide a version of the method C<get_colour_for>:
see L<METHOD get_colour_for> and L<SYNOPSIS> for details.


=head1 CONSTRUCTOR (new)

The following paramter fields are added to the base module's fields:

=over 4

=item display

Set to C<hex> for display as a unified distance matrix, rather than
as the default plain grid;

=item display_scale

Set with a factor to effect the size of the display.

=item show_bmu

Show the current BMU during training.

=item show_training

Display updates during training.

=item label_bmu

=item label_all

Displays labels...

=item MainLoop

Calls TK's C<MainLoop> at the end of training.

=item missing_colour

When selecting a colour using L<METHOD get_colour_for>,
every node weight holding the value of C<missing_mask>
will be given the value of this paramter. If this paramter
is not defined, the default is 0.

=back

=cut

use strict;
use warnings;
use Carp qw/cluck carp confess croak/;

use base "AI::NeuralNet::Kohonen";

use Tk;
use Tk::Canvas;
use Tk::Label;
use Tk qw/DoOneEvent DONT_WAIT/;



=head1 METHOD train

Over-rides the base class to provide TK displays of the map.

=cut

sub train { my ($self,$epochs) = (shift,shift);
	$epochs = $self->{epochs} unless defined $epochs;
	$self->{display_scale} = 10 if not defined 	$self->{display_scale};

	&{$self->{train_start}} if exists $self->{train_start};

	$self->prepare_display if not defined $self->{_mw} or ref $self->{_mw} ne 'MainWindow';

	# Replaces Tk's MainLoop
    for (0..$self->{epochs}) {
		if ($self->{_quit_flag}) {
			$self->{_mw}->destroy;
			$self->{_mw} = undef;
			return;
		}
		$self->{t}++;				# Measure epoch
		&{$self->{epoch_start}} if exists $self->{epoch_start};

		for (0..$#{$self->{input}}){
			my $target = $self->_select_target;
			my $bmu = $self->find_bmu($target);

			$self->_adjust_neighbours_of($bmu,$target);

			if (exists $self->{show_training}){
				if ($self->{show_bmu}){
					$self->plot_map(bmu_x=>$bmu->[1],bmu_y=>$bmu->[2]);
				} else {
					$self->plot_map;
				}
				$self->{_label_txt} = sprintf("Epoch: %04d",$self->{t})."  "
				. "Learning: $self->{l}  "
				. sprintf("BMU: %02d,%02d",$bmu->[1],$bmu->[2])."  "
				.( exists $target->{class}? "Target: [$target->{class}]  " : "")
				;
				$self->{_canvas}->update;
				$self->{_label}->update;
				DoOneEvent(DONT_WAIT);		# be kind and process XEvents if they arise
			}
		}

		$self->_decay_learning_rate;
 		&{$self->{epoch_end}} if exists $self->{epoch_end};
	}

	$self->{_label_txt} = "Did $self->{t} epochs: ";
	$self->{_label_txt} .= "now smoothed." if $self->{smoothing};
	$_->smooth if $self->{smooth};
	$self->plot_map if $self->{MainLoop};
	&{$self->{train_end}} if exists $self->{train_end};
	MainLoop if $self->{MainLoop};

	return 1;
}

=head1 METHOD get_colour_for

This method is intended to be sub-classed.

Currently it only operates on the first three elements
of a weight vector, turning them into RGB values.

It returns the a TK colour for a node at position C<x>,C<y> in the
C<map> paramter.

Accepts: C<x> and C<y> co-ordinates in the map.

=cut

sub get_colour_for { my ($self,$x,$y) = (shift,shift,shift);
	my $_0 = $self->{map}->[$x]->[$y]->{weight}->[0];
	$_0 = $self->{missing_colour} || 0 if $_0 eq $self->{missing_mask};
	my $_1 = $self->{map}->[$x]->[$y]->{weight}->[1];
	$_1 = $self->{missing_colour} || 0 if $_1 eq $self->{missing_mask};
	my $_2 = $self->{map}->[$x]->[$y]->{weight}->[2];
	$_2 = $self->{missing_colour} || 0 if $_2 eq $self->{missing_mask};
	return sprintf("#%02x%02x%02x",
		(int (255 * $_0)),
		(int (255 * $_1)),
		(int (255 * $_2)),
	);
}


=head1 METHOD prepare_display

Depracated: see L<METHOD create_empty_map>.

=cut

sub prepare_display {
	return $_[0]->create_empty_map;
}

=head1 METHOD create_empty_map

Sets up a TK C<MainWindow> and C<Canvas> to
act as an empty map.

=cut

sub create_empty_map { my $self = shift;
	my ($w,$h);
	if ($self->{display} and $self->{display} eq 'hex'){
		$w = ($self->{map_dim_x}+1) * ($self->{display_scale}+2);
		$h = ($self->{map_dim_y}+1) * ($self->{display_scale}+2);
	} else {
		$w = ($self->{map_dim_x}+1) * ($self->{display_scale});
		$h = ($self->{map_dim_y}+1) * ($self->{display_scale});
	}
	$self->{_mw} = MainWindow->new(
		-width	=> $w + 20,
		-height	=> $h + 20,
	);
	$self->{_mw}->fontCreate(qw/TAG -family verdana -size 8 -weight bold/);
	$self->{_mw}->resizable( 0, 0);
    $self->{_quit_flag} = 0;
    $self->{_mw}->protocol('WM_DELETE_WINDOW' => sub {$self->{_quit_flag}=1});
	$self->{_canvas} = $self->{_mw}->Canvas(
		-width	=> $w,
		-height	=> $h,
		-relief	=> 'raised',
		-border => 2,
	);
	$self->{_canvas}->pack(-side=>'top');
	$self->{_label} = $self->{_mw}->Button(
		-command      => sub { $self->{_mw}->destroy;$self->{_mw} = undef; },
		-relief       => 'groove',
		-text         => ' ',
		-wraplength   => $w,
		-textvariable => \$self->{_label_txt}
	);
	$self->{_label}->pack(-side=>'top');
	return 1;
}


=head1 METHOD plot_map

Plots the map on the existing canvas. Arguments are supplied
in a hash with the following keys as options:

The values of C<bmu_x> and C<bmu_y> represent The I<x> and I<y>
co-ordinates of unit to highlight using the value in the
C<hicol> to highlight it with colour. If no C<hicolo> is provided,
it default to red.

When called, this method also sets the object field flag C<plotted>:
currently, this prevents C<main_loop> from calling this routine.

See also L<METHOD get_colour_for>.

=cut

sub plot_map { my ($self,$args) = (shift,{@_});
	$self->{plotted} = 1;
	# MW may have been destroyed
	$self->prepare_display if not defined $self->{_mw};
	my $yo = 5+($self->{display_scale}/2);
	for my $x (0..$self->{map_dim_x}){
		for my $y (0..$self->{map_dim_y}){
			my $colour;
			if ($args->{bmu_x} and $args->{bmu_x}==$x and $args->{bmu_y}==$y){
				$colour = $args->{hicol} || 'red';
			} else {
				$colour = $self->get_colour_for ($x,$y);
			}
			if ($self->{display} and $self->{display} eq 'hex'){
				my $xo = 5+($y % 2) * ($self->{display_scale}/2);

				$self->{_canvas}->create(
					polygon	=> [
						$xo + (($x)*$self->{display_scale} ),
						$yo + (($y)*$self->{display_scale} ),

						# polygon only:
						$xo + (($x)*($self->{display_scale})+($self->{display_scale}/2) ),
						$yo + (($y)*($self->{display_scale})-($self->{display_scale}/2) ),
						#

						$xo + (($x)*($self->{display_scale})+$self->{display_scale} ),
						$yo + (($y)*$self->{display_scale} ),

						$xo + (($x)*($self->{display_scale})+$self->{display_scale} ),
						$yo + (($y)*($self->{display_scale})+($self->{display_scale}/2) ),

						# Polygon only:
						$xo + (($x)*($self->{display_scale})+($self->{display_scale}/2) ),
						$yo + (($y)*($self->{display_scale})+($self->{display_scale}) ),
						#

						$xo + (($x)*$self->{display_scale} ),
						$yo + (($y)*($self->{display_scale})+($self->{display_scale}/2) ),

					],
					-outline	=> "black",
					-fill 		=> $colour,
				);
			}
			else {
				$self->{_canvas}->create(
					rectangle	=> [
						$x*$self->{display_scale} +1,
						$y*$self->{display_scale} +1,
						$x*($self->{display_scale})+$self->{display_scale} +1,
						$y*($self->{display_scale})+$self->{display_scale} +1
					],
					-outline	=> "black",
					-fill 		=> $colour,
				);
			}

			# Label
			if ($self->{label_all}){
				my $txt;
				unless ( $txt = $self->{map}->[$x]->[$y]->{class}){
					$txt = "";
				}
				$self->label_map($x,$y,"+$txt");
			}

		}
	}
	if ($self->{label_bmu}){
		my $txt;
		unless ( $txt = $self->{map}->[$args->{bmu_x}]->[$args->{bmu_y}]->{class}){
			$txt = "";
		}
		$self->label_map(
			$args->{bmu_x}, $args->{bmu_y}, "+$txt"
		);
	}

	$self->{_canvas}->update;
	$self->{_label}->update;

	return 1;
}

=head1 METHOD label_map

Put a text label on the map for the node at the I<x,y> co-ordinates
supplied in the first two paramters, using the text supplied in the
third.

Very naive: no attempt to check the text will appear on the map.

=cut

sub label_map { my ($self,$x,$y,$t) = (shift,shift,shift,shift);
	$self->{_canvas}->createText(
		$x*$self->{display_scale}+($self->{display_scale}),
		$y*$self->{display_scale}+($self->{display_scale}),
		-text	=> $t,
		-anchor => 'w',
		-fill 	=> 'white',
		-font	=> 'TAG',
	);
}


=head1 METHOD main_loop

Calls TK's C<MainLoop> to keep a window open until the user closes it.

=cut

sub main_loop { my $self = shift;
	$self->plot_map unless $self->{plotted};
	MainLoop;
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
















