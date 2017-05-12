package AI::NeuralNet::Kohonen;

use vars qw/$VERSION/;
$VERSION = 0.142;	# 08 August 2006 test lost input file

=head1 NAME

AI::NeuralNet::Kohonen - Kohonen's Self-organising Maps

=cut

use strict;
use warnings;
use Carp qw/croak cluck confess/;

use AI::NeuralNet::Kohonen::Node;
use AI::NeuralNet::Kohonen::Input;

=head1 SYNOPSIS

	$_ = AI::NeuralNet::Kohonen->new(
		map_dim_x => 39,
		map_dim_y => 19,
		epochs    => 100,
		table     =>
	"3
	1 0 0 red
	0 1 0 yellow
	0 0 1 blue
	0 1 1 cyan
	1 1 0 yellow
	1 .5 0 orange
	1 .5 1 pink"
	);

	$_->train;
	$_->save_file('mydata.txt');
	exit;

=head1 DESCRIPTION

An illustrative implimentation of Kohonen's Self-organising Feature Maps (SOMs)
in Perl. It's not fast - it's illustrative. In fact, it's slow: but it is illustrative....

Have a look at L<AI::NeuralNet::Kohonen::Demo::RGB> for an example of
visualisation of the map.

I'll maybe add some more text here later.

=head1 DEPENDENCIES

	AI::NeuralNet::Kohonen::Node
	AI::NeuralNet::Kohonen::Input

=head1 EXPORTS

None

=head1 CONSTRUCTOR new

Instantiates object fields:

=over 4

=item input_file

A I<SOM_PAK> training file to load. This does not prevent
other input methods (C<input>, C<table>) being processed, but
it does over-ride any specifications (C<weight_dim>) which may
have been explicitly handed to the constructor.

See also L</FILE FORMAT> and L</METHOD load_input>.

=item input

A reference to an array of training vectors, within which each vector
is represented by an array:

	[ [v1a, v1b, v1c], [v2a,v2b,v2c], ..., [vNa,vNb,vNc] ]

See also C<table>.

=item table

The contents of a file of the format that could be supplied to
the C<input_file> field.

=item input_names

A name for each dimension of the input vectors.

=item map_dim_x

=item map_dim_y

The dimensions of the feature map to create - defaults to a toy 19.
(note: this is Perl indexing, starting at zero).

=item epochs

Number of epochs to run for (see L<METHOD train>).
Minimum number is C<1>.

=item learning_rate

The initial learning rate.

=item train_start

Reference to code to call at the begining of training.

=item epoch_start

Reference to code to call at the begining of every epoch
(such as a colour calibration routine).

=item epoch_end

Reference to code to call at the end of every epoch
(such as a display routine).

=item train_end

Reference to code to call at the end of training.

=item targeting

If undefined, random targets are chosen; otherwise
they're iterated over. Just for experimental purposes.

=item smoothing

The amount of smoothing to apply by default when C<smooth>
is applied (see L</METHOD smooth>).

=item neighbour_factor

When working out the size of the neighbourhood of influence,
the average of the dimensions of the map are divided by this variable,
before the exponential function is applied: the default value is 2.5,
but you may with to use 2 or 4.

=item missing_mask

Used to signify data is missing in an input vector. Defaults
to C<x>.

=back

Private fields:

=over 4

=item time_constant

The number of iterations (epochs) to be completed, over the log of the map radius.

=item t

The current epoch, or moment in time.

=item l

The current learning rate.

=item map_dim_a

Average of the map dimensions.

=back

=cut

sub new {
	my $class					= shift;
	my %args					= @_;
	my $self 					= bless \%args,$class;

	$self->{missing_mask}		= 'x' unless defined $self->{missing_mask};
	$self->_process_table if defined $self->{table};	# Creates {input}
	$self->load_input($self->{input_file}) if defined $self->{input_file};	# Creates {input}
	if (not defined $self->{input}){
		cluck "No {input} supplied!";
		return undef;
	}

	$self->{map_dim_x}			= 19 unless defined $self->{map_dim_x};
	$self->{map_dim_y}			= 19 unless defined $self->{map_dim_y};
	# Legacy from...yesterday
	if ($self->{map_dim}){
		$self->{map_dim_x} 		= $self->{map_dim_y} = $self->{map_dim}
	}
	if (not defined $self->{map_dim_x} or $self->{map_dim_x}==0
	 or not defined $self->{map_dim_y} or $self->{map_dim_y}==0){
		 confess "No map dimensions in the input!";
	 }
	if ($self->{map_dim_x}>$self->{map_dim_y}){
		$self->{map_dim_a} 		= $self->{map_dim_y} + (($self->{map_dim_x}-$self->{map_dim_y})/2)
	} else {
		$self->{map_dim_a} 		= $self->{map_dim_x} + (($self->{map_dim_y}-$self->{map_dim_x})/2)
	}
	$self->{neighbour_factor}	= 2.5 unless $self->{neighbour_factor};
	$self->{epochs}				= 99 unless defined $self->{epochs};
	$self->{epochs}				= 1 if $self->{epochs}<1;
	$self->{time_constant}		= $self->{epochs} / log($self->{map_dim_a}) unless $self->{time_constant};	# to base 10?
	$self->{learning_rate}		= 0.5 unless $self->{learning_rate};
	$self->{l}					= $self->{learning_rate};
	if (not $self->{weight_dim}){
		cluck "{weight_dim} not set";
		return undef;
	}
	$self->randomise_map;
	return $self;
}




=head1 METHOD randomise_map

Populates the C<map> with nodes that contain random real nubmers.

See L<AI::NerualNet::Kohonen::Node/CONSTRUCTOR new>.

=cut

sub randomise_map { my $self=shift;
	confess "{weight_dim} not set" unless $self->{weight_dim};
	confess "{map_dim_x} not set" unless $self->{map_dim_x};
	confess "{map_dim_y} not set" unless $self->{map_dim_y};
	for my $x (0..$self->{map_dim_x}){
		$self->{map}->[$x] = [];
		for my $y (0..$self->{map_dim_y}){
			$self->{map}->[$x]->[$y] = new AI::NeuralNet::Kohonen::Node(
				dim => $self->{weight_dim},
				missing_mask => $self->{missing_mask},
			);
		}
	}
}


=head1 METHOD clear_map

As L<METHOD randomise_map> but sets all C<map> nodes to
either the value supplied as the only paramter, or C<undef>.

=cut

sub clear_map { my $self=shift;
	confess "{weight_dim} not set" unless $self->{weight_dim};
	confess "{map_dim_x} not set" unless $self->{map_dim_x};
	confess "{map_dim_y} not set" unless $self->{map_dim_y};
	my $val = shift || $self->{missing_mask};
	my $w = [];
	foreach (0..$self->{weight_dim}){
		push @$w, $val;
	}
	for my $x (0..$self->{map_dim_x}){
		$self->{map}->[$x] = [];
		for my $y (0..$self->{map_dim_y}){
			$self->{map}->[$x]->[$y] = new AI::NeuralNet::Kohonen::Node(
				weight		 => $w,
				dim 		 => $self->{weight_dim},
				missing_mask => $self->{missing_mask},
			);
		}
	}
}




=head1 METHOD train

Optionally accepts a parameter that is the number of epochs
for which to train: the default is the value in the C<epochs> field.

An epoch is composed of A number of generations, the number being
the total number of input vectors.

For every generation, iterates:

=over 4

=item 1

selects a target from the input array (see L</PRIVATE METHOD _select_target>);

=item 2

finds the best-matching unit (see L</METHOD find_bmu>);

=item 3

adjusts the neighbours of the BMU (see L</PRIVATE METHOD _adjust_neighbours_of>);

=back

At the end of every generation, the learning rate is decayed
(see L</PRIVATE METHOD _decay_learning_rate>).

See C<CONSTRUCTOR new> for details of applicable callbacks.

Returns a true value.

=cut

sub train { my ($self,$epochs) = (shift,shift);
	$epochs = $self->{epochs} unless defined $epochs;
	&{$self->{train_start}} if exists $self->{train_start};
	for my $epoch (1..$epochs){
		$self->{t} = $epoch;
		&{$self->{epoch_start}} if exists $self->{epoch_start};
		for (0..$#{$self->{input}}){
			my $target = $self->_select_target;
			my $bmu = $self->find_bmu($target);
			$self->_adjust_neighbours_of($bmu,$target);
		}
		$self->_decay_learning_rate;
		&{$self->{epoch_end}} if exists $self->{epoch_end};
	}
	&{$self->{train_end}} if $self->{train_end};
	return 1;
}


=head1 METHOD find_bmu

For a specific taraget, finds the Best Matching Unit in the map
and return the x/y index.

Accepts: a reference to an array that is the target.

Returns: a reference to an array that is the BMU (and should
perhaps be abstracted as an object in its own right), indexed as follows:

=over 4

=item 0

euclidean distance from the supplied target

=item 1, 2

I<x> and I<y> co-ordinate in the map

=back

See L</METHOD get_weight_at>,
and L<AI::NeuralNet::Kohonen::Node/distance_from>,

=cut


sub find_bmu { my ($self,$target) = (shift,shift);
	my $closest = [];	# [value, x,y] value and co-ords of closest match
	for my $x (0..$self->{map_dim_x}){
		for my $y (0..$self->{map_dim_y}){
			my $distance = $self->{map}->[$x]->[$y]->distance_from( $target );
			$closest = [$distance,0,0] if $x==0 and $y==0;
			$closest = [$distance,$x,$y] if $distance < $closest->[0];
		}
	}
	return $closest;
}

=head1 METHOD get_weight_at

Returns a reference to the weight array at the supplied I<x>,I<y>
co-ordinates.

Accepts: I<x>,I<y> co-ordinates, each a scalar.

Returns: reference to an array that is the weight of the node, or
C<undef> on failure.

=cut

sub get_weight_at { my ($self,$x,$y) = (shift,shift,shift);
	return undef if $x<0 or $y<0 or $x>$self->{map_dim_x} or $y>$self->{map_dim_y};
	return $self->{map}->[$x]->[$y]->{weight};
}



=head1 METHOD get_results

Finds and returns the results for all input vectors in the supplied
reference to an array of arrays,
placing the values in the C<results> field (array reference),
and, returning it either as an array or as it is, depending on
the calling context

If no array reference of input vectors is supplied, will use
the values in the C<input> field.

Individual results are in the array format as described in
L<METHOD find_bmu>.

See L<METHOD find_bmu>, and L</METHOD get_weight_at>.

=cut

sub get_results { my ($self,$targets)=(shift,shift);
	$self->{results} = [];
	if (not defined $targets){
		$targets = $self->{input};
	} elsif (not $targets eq $self->{input}){
		foreach (@$targets){
			next if ref $_ eq 'AI::NeuralNet::Kohonen::Input';
			$_ = new AI::NeuralNet::Kohonen::Input(values=>$_);
		}
	}
	foreach my $target (@{ $targets}){
		$_ = $self->find_bmu($target);
		push @$_, $target->{class}||"?";
		push @{$self->{results}}, $_;
	}
	# Make it a scalar if it's a scalar
#	if ($#{$self->{results}} == 0){
#		$self->{results} = @{$self->{results}}[0];
#	}
	return wantarray? @{$self->{results}} : $self->{results};
}


=head1 METHOD map_results

Clears the C<map> and fills it with the results.

The sole paramter is passed to the L<METHOD clear_map>.
L<METHOD get_results> is then called, and the results
returned fed into the object field C<map>.

This may change, as it seems misleading to re-use that field.

=cut

sub map_results { my $self=shift;

}


=head1 METHOD dump

Print the current weight values to the screen.

=cut

sub dump { my $self=shift;
	print "    ";
	for my $x (0..$self->{map_dim_x}){
		printf ("  %02d ",$x);
	}
	print"\n","-"x107,"\n";
	for my $x (0..$self->{map_dim_x}){
		for my $w (0..$self->{weight_dim}){
			printf ("%02d | ",$x);
			for my $y (0..$self->{map_dim_y}){
				printf("%.2f ", $self->{map}->[$x]->[$y]->{weight}->[$w]);
			}
			print "\n";
		}
		print "\n";
	}
}

=head1 METHOD smooth

Perform gaussian smoothing upon the map.

Accepts: the length of the side of the square gaussian mask to apply.
If not supplied, uses the value in the field C<smoothing>; if that is
empty, uses the square root of the average of the map dimensions
(C<map_dim_a>).

Returns: a true value.

=cut

sub smooth { my ($self,$smooth) = (shift,shift);
	$smooth = $self->{smoothing} if not $smooth and defined $self->{smoothing};
	return unless $smooth;
	$smooth = int( sqrt $self->{map_dim_a} );
	my $mask = _make_gaussian_mask($smooth);

	# For every weight at every point
	for my $x (0..$self->{map_dim_x}){
		for my $y (0..$self->{map_dim_y}){
			for my $w (0..$self->{weight_dim}){
				# Apply the mask
				for my $mx (0..$smooth){
					for my $my (0..$smooth){
						$self->{map}->[$x]->[$y]->{weight}->[$w] *= $mask->[$mx]->[$my];
					}
				}
			}
		}
	}
	return 1;
}



=head1 METHOD load_input

Loads a SOM_PAK-format file of input vectors.

This method is automatically accessed if the constructor is supplied
with an C<input_file> field.

Requires: a path to a file.

Returns C<undef> on failure.

See L</FILE FORMAT>.

=cut

sub load_input { my ($self,$path) = (shift,shift);
	local *IN;
	if (not open IN,$path){
		warn "Could not open file <$path>: $!";
		return undef;
	}
	@_ = <IN>;
	close IN;
	$self->_process_input_text(\@_);
	return 1;
}


=head1 METHOD save_file

Saves the map file in I<SOM_PAK> format (see L<METHOD load_input>)
at the path specified in the first argument.

Return C<undef> on failure, a true value on success.

=cut

sub save_file { my ($self,$path) = (shift,shift);
	local *OUT;
	if (not open OUT,">$path"){
		warn "Could not open file for writing <$path>: $!";
		return undef;
	}
	#- Dimensionality of the vectors (integer, compulsory).
	print OUT ($self->{weight_dim}+1)," ";	# Perl indexing
	#- Topology type, either hexa or rect (string, optional, case-sensitive).
	if (not defined $self->{display}){
		print OUT "rect ";
	} else { # $self->{display} eq 'hex'
		print OUT "hexa ";
	}
	#- Map dimension in x-direction (integer, optional).
	print OUT $self->{map_dim_x}." ";
	#- Map dimension in y-direction (integer, optional).
	print OUT $self->{map_dim_y}." ";
	#- Neighborhood type, either bubble or gaussian (string, optional, case-sen- sitive).
	print OUT "gaussian ";
	# End of header
	print OUT "\n";

	# Format input data
	foreach (@{$self->{input}}){
		print OUT join("\t",@{$_->{values}});
		if ($_->{class}){
			print OUT " $_->{class} " ;
		}
		print OUT "\n";
	}
	# EOF
	print OUT chr 26;
	close OUT;
	return 1;
}


#
# Process ASCII from table field or input file
# Accepts: ASCII as array or array ref
#
sub _process_input_text { my ($self) = (shift);
	if (not defined $_[1]){
		if (ref $_[0] eq 'ARRAY'){
			@_ = @{$_[0]};
		} else {
			@_ = split/[\n\r\f]+/,$_[0];
		}
	}
	chomp @_;
	my @specs = split/\s+/,(shift @_);
	#- Dimensionality of the vectors (integer, compulsory).
	$self->{weight_dim} = shift @specs;
	$self->{weight_dim}--; # Perl indexing
	#- Topology type, either hexa or rect (string, optional, case-sensitive).
	my $display		    = shift @specs;
	if (not defined $display and exists $self->{display}){
		# Intentionally blank
	} elsif (not defined $display){
		$self->{display} = undef;
	} elsif ($display eq 'hexa'){
		$self->{display} = 'hex'
	} elsif ($display eq 'rect'){
		$self->{display} = undef;
	}
	#- Map dimension in x-direction (integer, optional).
	$_				      = shift @specs;
	$self->{map_dim_x}    = $_ if defined $_;
	#- Map dimension in y-direction (integer, optional).
	$_				      = shift @specs;
	$self->{map_dim_y}    = $_ if defined $_;
	#- Neighborhood type, either bubble or gaussian (string, optional, case-sen- sitive).
	# not implimented

	# Format input data
	foreach (@_){
		$self->_add_input_from_str($_);
	}
	return 1;
}


=head1 PRIVATE METHOD _select_target

Return a random target from the training set in the C<input> field,
unless the C<targeting> field is defined, when the targets are
iterated over.

=cut

sub _select_target { my $self=shift;
	if (not $self->{targeting}){
		return $self->{input}->[
			(int rand(scalar @{$self->{input}}))
		];
	}
	else {
		$self->{tar}++;
		if ($self->{tar}>$#{ $self->{input} }){
			$self->{tar} = 0;
		}
		return $self->{input}->[$self->{tar}];
	}
}


=head1 PRIVATE METHOD _adjust_neighbours_of

Accepts: a reference to an array containing
the distance of the BMU from the target, as well
as the x and y co-ordinates of the BMU in the map;
a reference to the target, which is an
C<AI::NeuralNet::Kohonen::Input> object.

Returns: true.

=head2 FINDING THE NEIGHBOURS OF THE BMU

	                        (      t   )
	sigma(t) = sigma(0) exp ( - ------ )
	                        (   lambda )

Where C<sigma> is the width of the map at any stage
in time (C<t>), and C<lambda> is a time constant.

Lambda is our field C<time_constant>.

The map radius is naturally just half the map width.

=head2 ADJUSTING THE NEIGHBOURS OF THE BMU

	W(t+1) = W(t) + THETA(t) L(t)( V(t)-W(t) )

Where C<L> is the learning rate, C<V> the target vector,
and C<W> the weight. THETA(t) represents the influence
of distance from the BMU upon a node's learning, and
is calculated by the C<Node> class - see
L<AI::NeuralNet::Kohonen::Node/distance_effect>.

=cut

sub _adjust_neighbours_of { my ($self,$bmu,$target) = (shift,shift,shift);
	my $neighbour_radius = int (
		($self->{map_dim_a}/$self->{neighbour_factor}) * exp(- $self->{t} / $self->{time_constant})
	);

	# Distance from co-ord vector (0,0) as integer
	# Basically map_width * y  +  x
	my $centre = ($self->{map_dim_a}*$bmu->[2])+$bmu->[1];
	# Set the class of the BMU
	$self->{map}->[ $bmu->[1] ]->[ $bmu->[2] ]->{class} = $target->{class};

	for my $x ($bmu->[1]-$neighbour_radius .. $bmu->[1]+$neighbour_radius){
		next if $x<0 or $x>$self->{map_dim_x};		# Ignore those not mappable
		for my $y ($bmu->[2]-$neighbour_radius .. $bmu->[2]+$neighbour_radius){
			next if $y<0 or $y>$self->{map_dim_y};	# Ignore those not mappable
			# Skip node if it is out of the circle of influence
			next if (
				(($bmu->[1] - $x) * ($bmu->[1] - $x)) + (($bmu->[2] - $y) * ($bmu->[2] - $y))
			) > ($neighbour_radius * $neighbour_radius);

			# Adjust the weight
			for my $w (0..$self->{weight_dim}){
				next if $target->{values}->[$w] eq $self->{map}->[$x]->[$y]->{missing_mask};
				my $weight = \$self->{map}->[$x]->[$y]->{weight}->[$w];
				$$weight = $$weight + (
					$self->{map}->[$x]->[$y]->distance_effect($bmu->[0], $neighbour_radius)
					* ( $self->{l} * ($target->{values}->[$w] - $$weight) )
				);
			}
		}
	}
}


=head1 PRIVATE METHOD _decay_learning_rate

Performs a gaussian decay upon the learning rate (our C<l> field).

	              (       t   )
	L(t) = L  exp ( -  ------ )
	        0     (    lambda )

=cut

sub _decay_learning_rate { my $self=shift;
	$self->{l} =  (
		$self->{learning_rate} * exp(- $self->{t} / $self->{time_constant})
	);
}


=head1 PRIVATE FUNCTION _make_gaussian_mask

Accepts: size of mask.

Returns: reference to a 2d array that is the mask.

=cut

sub _make_gaussian_mask { my ($smooth) = (shift);
	my $f = 4; # Cut-off threshold
	my $g_mask_2d = [];
	for my $x (0..$smooth){
		$g_mask_2d->[$x] = [];
		for my $y (0..$smooth){
			$g_mask_2d->[$x]->[$y] =
				_gauss_weight( $x-($smooth/2), $smooth/$f)
			  * _gauss_weight( $y-($smooth/2), $smooth/$f );
		}
	}
	return $g_mask_2d;
}

=head1 PRIVATE FUNCTION _gauss_weight

Accepts: two paramters: the first, C<r>, gives the distance from the mask centre,
the second, C<sigma>, specifies the width of the mask.

Returns the gaussian weight.

See also L<_decay_learning_rate>.

=cut

sub _gauss_weight { my ($r, $sigma) = (shift,shift);
	return exp( -($r**2) / (2 * $sigma**2) );
}


=head1 PUBLIC METHOD quantise_error

Returns the quantise error for either the supplied points,
or those in the C<input> field.

=cut


sub quantise_error { my ($self,$targets) = (shift,shift);
	my $qerror=0;
	if (not defined $targets){
		$targets = $self->{input};
	} else {
		foreach (@$targets){
			if (not ref $_ or ref $_ ne 'ARRAY'){
				croak "Supplied target parameter should be an array of arrays!"
			}
			$_ = new AI::NeuralNet::Kohonen::Input(values=>$_);
		}
	}

	# Recieves an array of ONE element,
	# should be an array of an array of elements
	my @bmu = $self->get_results($targets);

	# Check input and output dims are the same
	if ($#{$self->{map}->[0]->[1]->{weight}} != $targets->[0]->{dim}){
		confess "target input and map dimensions differ";
	}

	for my $i (0..$#bmu){
		foreach my $w (0..$self->{weight_dim}){
			$qerror += $targets->[$i]->{values}->[$w]
			- $self->{map}->[$bmu[$i]->[1]]->[$bmu[$i]->[2]]->{weight}->[$w];
		}
	}
	$qerror /= scalar @$targets;
	return $qerror;
}


=head1 PRIVATE METHOD _add_input_from_str

Adds to the C<input> field an input vector in SOM_PAK-format
whitespace-delimited ASCII.

Returns C<undef> on failure to add an item (perhaps because
the data passed was a comment, or the C<weight_dim> flag was
not set); a true value on success.

=cut

sub _add_input_from_str { my ($self) = (shift);
	$_ = shift;
	s/#.*$//g;
	return undef if /^$/ or not defined $self->{weight_dim};
	my @i = split /\s+/,$_;
	return undef if $#i < $self->{weight_dim}; # catch bad lines
	# 'x' in files signifies unknown: we prefer undef?
#	@i[0..$self->{weight_dim}] = map{
#		$_ eq 'x'? undef:$_
#	} @i[0..$self->{weight_dim}];
	my %args = (
		dim 	=> $self->{weight_dim},
		values	=> [ @i[0..$self->{weight_dim}] ],
	);
	$args{class} = $i[$self->{weight_dim}+1] if $i[$self->{weight_dim}+1];
	$args{enhance} = $i[$self->{weight_dim}+1] if $i[$self->{weight_dim}+2];
	$args{fixed} = $i[$self->{weight_dim}+1] if $i[$self->{weight_dim}+3];
	push @{$self->{input}}, new AI::NeuralNet::Kohonen::Input(%args);

	return 1;
}


#
# Processes the 'table' paramter to the constructor
#
sub _process_table { my $self = shift;
	$_ = $self->_process_input_text( $self->{table} );
	undef $self->{table};
	return $_;
}


__END__
1;

=head1 FILE FORMAT

This module has begun to attempt the I<SOM_PAK> format:
I<SOM_PAK> file format version 3.1 (April 7, 1995),
Helsinki University of Technology, Espoo:

=over 4

The input data is stored in ASCII-form as a list of entries, one line
...for each vectorial sample.

The first line of the file is reserved for status knowledge of the
entries; in the present version it is used to define the following
items (these items MUST occur in the indicated order):

   - Dimensionality of the vectors (integer, compulsory).
   - Topology type, either hexa or rect (string, optional, case-sensitive).
   - Map dimension in x-direction (integer, optional).
   - Map dimension in y-direction (integer, optional).
   - Neighborhood type, either bubble or gaussian (string, optional, case-sen-
      sitive).

...

Subsequent lines consist of n floating-point numbers followed by an
optional class label (that can be any string) and two optional
qualifiers (see below) that determine the usage of the corresponding
data entry in training programs.  The data files can also contain an
arbitrary number of comment lines that begin with '#', and are
ignored. (One '#' for each comment line is needed.)

If some components of some data vectors are missing (due to data
collection failures or any other reason) those components should be
marked with 'x'...[in processing, these] are ignored.

...

Each data line may have two optional qualifiers that determine the
usage of the data entry during training. The qualifiers are of the
form codeword=value, where spaces are not allowed between the parts of
the qualifier. The optional qualifiers are the following:

=over 4

=item -

Enhancement factor: e.g. weight=3.  The training rate for the
corresponding input pattern vector is multiplied by this
parameter so that the reference vectors are updated as if this
input vector were repeated 3 times during training (i.e., as if
the same vector had been stored 2 extra times in the data file).

=item -

Fixed-point qualifier: e.g. fixed=2,5.  The map unit defined by
the fixed-point coordinates (x = 2; y = 5) is selected instead of
the best-matching unit for training. (See below for the definition
of coordinates over the map.) If several inputs are forced to
known locations, a wanted orientation results in the map.

=back

=back

Not (yet) implimented in file format:

=over 4

=item *

hexa/rect is only visual, and only in the ::Demo::RGB package atm

=item *

I<neighbourhood type> is always gaussian.

=item *

i<x> for missing data.

=item *

the two optional qualifiers

=back

=cut

=head1 SEE ALSO

See L<AI::NeuralNet::Kohonen::Node/distance_from>;
L<AI::NeuralNet::Kohonen::Demo::RGB>.

L<The documentation for C<SOM_PAK>|ftp://cochlea.hut.fi/pub/som_pak>,
which has lots of advice on map building that may or may not be applicable yet.

A very nice explanation of Kohonen's algorithm:
L<AI-Junkie SOM tutorial part 1|http://www.fup.btinternet.co.uk/aijunkie/som1.html>

=head1 AUTHOR AND COYRIGHT

This implimentation Copyright (C) Lee Goddard, 2003-2006.
All Rights Reserved.

Available under the same terms as Perl itself.
