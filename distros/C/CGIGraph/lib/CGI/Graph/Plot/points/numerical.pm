package CGI::Graph::Plot::points::numerical;

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
# returns what is passed in since all points are already numerical
#

sub count {
	my $self = shift;
	return @_;
}

#
# returns a reference to X, Y, and select arrays that will be used to create 
# graph images.
#

sub valuesInRange{
	my $self = shift;

	my @selected = split("",$self->{selected});

        my @row = $self->{table}->col('_row');
        my @X = ($self->{table})->col($self->{X});
        my @Y = ($self->{table})->col($self->{Y});

	my @returnY;
	my $yFlag;

	# determine if elements are selected and/or in range
        for (0..$#X) {
                push (@selectDraw, $selected[$row[$_]-1]);
		# determines if element is in range
                if ($X[$_] >= $self->{x_min} && $X[$_] <= $self->{x_max} && 
		$Y[$_] >= $self->{y_min} && $Y[$_] <= $self->{y_max}) {
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
