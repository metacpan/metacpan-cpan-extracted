package CGI::Graph::Plot::points::string;

use CGI::Graph::Plot::points;

@ISA = ("CGI::Graph::Plot::points");

#
# makes call to parent class where all real work is done 
#

sub new {
        my ($pkg, $vars) = @_;
        my $class = ref($pkg) || $pkg;
        my $self = $class->SUPER::new($vars);
        return bless $self, $class;
}

#
# creates an array used for the X values of a graph. The numbers run 
# sequentially from 1 upward, and identical non-numerical values in the input 
# array are given the same number in the return array.
#

sub count {
	my $self = shift;
	my @X = @_;
	
	my @return;
	my $count = 1;

	# assign numerical x value for each identical non-numerical x
	for (0..$#X) {
		push (@return,$count);
		$count++ unless ($X[$_] eq $X[$_+1]);
	}

	push (@return,$count); # add extra value for space at end

	return (@return);
}

#
# returns a reference to X, Y, and select arrays that will be used to create 
# graph images. The X and Y values must fall between the min and max values, 
# the select value is just a flag to indicate if the point must be highlighted.
#

sub valuesInRange{
        my $self = shift;

	my @selected = split("",$self->{selected});

	my @row = $self->{table}->col('_row');
        my @X = $self->{table}->col($self->{X});
        my @Y = $self->{table}->col($self->{Y});

        @X = $self->count(@X);

	my (@returnX,@returnY,@selectDraw);
        my $yFlag;

	# determine if elements are selected and/or in range
        for (0..$#X) {
		push (@selectDraw, $selected[$row[$_]-1]);
		# determines if element is in range
                if (($X[$_] >= $self->{x_min} && $X[$_] <= $self->{x_max} && 
		$Y[$_] >= $self->{y_min} && $Y[$_] <= $self->{y_max})
		|| ($self->{grid})) {
                        push (@returnY,$Y[$_]);
                        $yFlag++;
                }
		# if element not in range, use undef
                else {
                        push (@returnY,undef);
                }
        }

	# make sure that returnY has at least one non-undef value
        unless ($yFlag) {
                $returnY[0]=$self->{y_min}-$self->{y_max};
        }

        return (\@X,\@returnY,\@selectDraw);
}

1;
