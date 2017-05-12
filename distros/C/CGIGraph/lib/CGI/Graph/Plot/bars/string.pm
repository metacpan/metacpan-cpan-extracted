package CGI::Graph::Plot::bars::string;

use CGI::Graph::Plot::bars;

@ISA = ("CGI::Graph::Plot::bars");

my %default = (label_size => 12,
	       max_x_values => 50);

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

		# obtain X value for selected bar
		my $X1 = ($self->{select})?$X[$self->{select}-1]:$X[0];
		my $X2 = ($self->{select})?$X[$self->{select}-1]:$X[-1];

		# update selection values for selected elements
                foreach (0..$self->{table}->nofRow()-1) {
			last if ($self->{table}->elm($_,$self->{X}) gt $X2);
                        if ($self->{table}->elm($_,$self->{X}) ge $X1) {
				if ($self->{select}) {
					$selected[$row[$_]-1] = 
					($self->{select_type} eq 'select')?1:0;
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

        return bless $self,$class;
}

sub count{   
	my $self = shift;
	my @S = $self->{table}->col($self->{X});
        my @X = $S[0];
        my @Y = (1);  # represents number of X values at index
        
	# count number of identical X values
        for ($i=1; $i < scalar(@S); $i++) {
                # X different than previous
                if ($S[$i] ne $S[$i-1]) {
                        push @X, $S[$i];
                        push @Y, 1;
                }
                # same as previous X
                else {  
                        $Y[$#Y]++;
                }
        }

        return (\@X,\@Y);
}

sub valuesInRange {
        my $self = shift;
	my $max_x_values = shift || $default{max_x_values};
	
	my @row = $self->{table}->col('_row');
	my @selected = split("",$self->{selected});

        my ($Xref,$Yref) = $self->count;
        my @X = @$Xref;
        my @Y = @$Yref;
	my (@dataX,@dataY,@selectDraw);

        my $last=0;
        my $count=0; # number of bars
	# determine which values are in range
        for ($i=0; $i<=$#X; $i++) {
                if ( (($i+1)/($#X+2) >= $self->{x_min}) && 
		(($i+1)/($#X+2) <= $self->{x_max}) ) {
                        push (@dataX, $X[$i]);
                        push (@dataY, $Y[$i]);
                        # find first occurrence of x label
                        for ($first=$last; $first<$self->{table}->nofRow; 
			$first++) {
                                last if ($X[$i] eq 
					$self->{table}->elm($first,$self->{X}));
                        }

                        # determine number of selected elements in this bar
                        for ($row=$first; $row < scalar(@selected); $row++) {
                                last if ($self->{table}->elm($row,$self->{X}) 
					ne $X[$i]);
                                if ($selected[$row[$row]-1] == 1) {
                                        $selectDraw[$count]++;
                                }
                        }
                        $last=$first;
                        $count++;
                }
        }

        # avoid returning more X values than can be handled
        if ($#dataX > $max_x_values) {
		my (@tempX,@tempY,@tempS);
                for ($i=0; $i<=$#dataX; $i+=($#dataX/$max_x_values)) { 
			push(@tempX,$dataX[$i]);
			push(@tempY,$dataY[$i]);
			push(@tempS,$selectDraw[$i]);
                }
		@dataX = @tempX;
		@dataY = @tempY;
		@selectDraw = @tempS;
        }

	# shorten labels
	foreach (0..$#dataX) {
		$drawX[$_] = sprintf("%.".$default{label_size}."s",$dataX[$_]);	
	}	
	return (\@dataX,\@drawX,\@dataY,\@selectDraw);
}

1;
