package CGI::Graph::Plot::bars::numerical;

use CGI::Graph::Plot::bars;

@ISA = ("CGI::Graph::Plot::bars");

%default = (
	label_size => 5,
	bins => 10
);

#
# calls parent class to initialize values. Selection values are changed, if 
# necessary.
#

sub new {
        my ($pkg, $vars) = @_;
        my $class = ref($pkg) || $pkg;
        my $self=$class->SUPER::new($vars);

        if ($self->{rand}) {
		return bless $self,$class;
        }

	$self->graphBounds;

        if ($self->{select} || $self->{select_list} eq 'Visible' || $self->{unselect_list} eq 'Visible') {
		my @selected = split("",$self->{selected});
		my @row = $self->{table}->col('_row');
                my ($Xref) = $self->valuesInRange();
                my @X = @$Xref;
		my ($X1,$X2);

		# obtain range for selected X bar(s)
		if ($self->{select}) {
                	($X1,$X2) = $X[$self->{select}-1] =~ /^(.*)->(.*)$/;
		}
		unless ($self->{select}) {
			($X1) = $X[0] =~ /^(.*)->/;
			($X2) = $X[-1] =~ /->(.*)$/;
		}

		# update selection values for selected elements
                foreach (0..$self->{table}->nofRow()-1) {
			last if ($self->{table}->elm($_,$self->{X}) > $X2);

                        if ($self->{table}->elm($_,$self->{X}) >= $X1) {
				if ($self->{select}) {
					$selected[$row[$_]-1] = 
					($self->{select_type} eq'select')?1:0;
				}
				else {
					$selected[$row[$_]-1] =
                                        ($self->{select_list} eq 'Visible')?1:0;
				}
                        }
                }

	        $self->{selected} = join("",@selected);
		$self->write_selected();
        }

        return bless $self, $class;
}

#
# returns X and Y values for a histogram
#

sub count {
	my $self = shift;
	my $drawPartial = shift if @_;

	my @selected = split("",$self->{selected});

        my @S = $self->{table}->col($self->{X}); 
	my @row = $self->{table}->col('_row');

        my $bins = $default{bins};
	my ($start,$end);

	# determine start and end values depending on 
	# what portion of the graph is to be drawn

	if ($drawPartial) {
	        my $delta = $S[-1]-$S[0];
	        $start = $self->{x_min}*$delta+$S[0];
	        $end = $self->{x_max}*$delta+$S[0];
	}

	else {
	        $start = $S[0];
	        $end = $S[-1];
	}

        my $int = $self->{X}=~/^[i]_/;
        my $size = ($int)?($end-$start+1)/$bins:($end-$start)/$bins;

	# if using integer values, do not allow more bins than needed
        while ($int) {
                $size = ($end-$start+1)/$bins;
                last if ($size >= 1);
                $bins-- if ($size < 1);
        }

	# put range values into X array
        my @X;
        my $range;
        foreach (0..$bins-1) {
                $range = ($int) ? 
			int($_*$size+$start).'->'.int(($_+1)*$size+$start-1)
	                :($_*$size+$start).'->'.(($_+1)*$size+$start);
                push @X, $range;
        }

	# count values in each X range and store results in Y
	# also note how many selected elements are in each range
        my @Y;
	my @selectDraw;
        foreach (0..$#X) {
                push @Y,0;
                $X[$_] =~ /(.*)->(.*)/;

		foreach $count (0..$#S) {
			if (($S[$count] >= $1) && ($S[$count] <= $2)) {
				$selectDraw[$_]++ if ($selected[$row[$count]-1]
					== 1);				
                	        $Y[$_]++;
			}
		}
        }

        return (\@X,\@Y,\@selectDraw);
}

#
# depending on what type of histogram is used, returns X and Y values.
#

sub valuesInRange {
        my $self = shift;

	my (@dataX,@drawX,@dataY,@selectDraw);

	# bar graph style, zooms in without re-calculating histogram
	if ($self->{histogram_type} eq "fixed") {
	        my ($Xref,$Yref,$Sref) = $self->count();
	        my @X = @$Xref;
	        my @Y = @$Yref;
		my @S = @$Sref;

	        for ($i=0; $i<=$#X; $i++) {
	                if ( (($i+1)/($#X+2) >= $self->{x_min}) && 
			(($i+1)/($#X+2) <= $self->{x_max}) ) {
	                        push (@dataX, $X[$i]);
	                        push (@dataY, $Y[$i]);
				push (@selectDraw, $S[$i]);
	                }
	        }
	}

	# "variable" graph, re-calculates histogram when zooming in
	else {
	        my ($Xref,$Yref,$Sref) = $self->count(1);
	        @dataX = @$Xref;
	        @dataY = @$Yref;
		@selectDraw = @$Sref;
	}

	# shorten labels
        foreach (0..$#dataX) {
		$dataX[$_] =~ /(.*)->(.*)/;
                $drawX[$_] = sprintf("%.$default{label_size}g->%".
		".$default{label_size}g", $1,$2);
	}
	return (\@dataX,\@drawX,\@dataY,\@selectDraw);
}
