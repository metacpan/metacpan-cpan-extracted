package sukill;

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: sukill 
 AUTHOR: Juan Lorenzo
 DATE: Oct 18 2012
 DESCRIPTION sukill a lists of header words
 or an single value
 Version 1

 STEPS ARE:
=cut

use Moose;
our $VERSION = '1.00';

my $newline    = '
';


sub new
{
    my $class = shift;
    my $sukill = {
	 "sukill",
        _tracl,  	=> shift,
        _min,  		=> shift,
        _count,		=> shift,
        _file,		=> shift,
    };
    # Print all the values just for clarification.
  #       print "Header Word is $sukill->{_headerword}\n";
  #       print "min is $sukill->{_min}\n";
  #       print "count is $sukill->{_count}\n";
         bless $sukill, $class;
         $sukill2="sssss";
         return $sukill;
 }

sub clear {
    my ($sukill) = @_;
    $sukill->{_count} 		= '';
    $sukill->{_file} 		= '';
    $sukill->{_min} 		= '';
    $sukill->{_mins} 		= '';
    $sukill->{_tracl} 		= '';
    $sukill->{_Step} 		= '';
    $sukill->{_Steps} 		= '';
    @kill_list       		= ();
    $len =0;
}


sub file {
    my ($sukill, $ref_file ) = @_;
    $sukill->{_file} = $$ref_file if defined($ref_file);
    return $sukill->{_file};
}


sub count {
    my ($sukill, $count ) = @_;
    $sukill->{_count} = $count if defined($count);
    return $sukill->{_count};
}

sub min {
    my ($sukill, $min ) = @_;
    $sukill->{_min} = $min if defined($min);
    return $sukill->{_min};
}


=pod

Usage 1:
To kill an array of trace numbers

Example:
       $sukill->tracl(\@array);
       $sukill->Steps()

Usage 1:
To kill a single of trace number
count=1 (default if omitted)

Example:
       $sukill->min('2');
       $sukill->Step()

If you read the file directly into sukill then also
us sukill->file('name')

=cut

sub mins {   # array of kill numbers
    my ($sukill, $ref_array) = @_;
    @kill_list = @$ref_array if defined($ref_array);
    #print("kill list is @kill_list\n\n");
    $len = @$ref_array;
    #for ($i=0; $i< $len; $i++) {
     #  $kill_list[$i] = $$ref_array[$i];
     #  print("kill_list: $kill_list[$i]\n\n");
    #}
}


sub tracl{   # array of kill numbers
    my ($sukill, $ref_array) = @_;
    @kill_list = @$ref_array if defined($ref_array);
    $len = @$ref_array;
}

sub Step{
    my ($sukill ) = @_;

    # count = 1 (default)
    if ($sukill->{_count} eq "") {
        $sukill->{_count} = 1;
    }
    $sukill->{_Step} = ' sukill'.
			' min='.$sukill->{_min}.
			' count='.$sukill->{_count};
    return $sukill->{_Step};
}

sub Steps{
    my ($sukill ) = @_;

    # count = 1 (default)
    if ($sukill->{_count} eq "") {
        $sukill->{_count} = 1;
    }

# if sukill is at the start of the flow
# for the first time
    $sukill->{_Steps} = ' sukill'.
                       	' min='.$kill_list[1].
			' count='.$sukill->{_count}.
                        ' < '.$sukill->{_file}.
                        ' \\'.$newline;

# for successive times
    for ($i=2; $i < $len; $i++) {
       $sukill->{_Steps} = $sukill->{_Steps}.
			   ' | '.
                           ' sukill'.
			   ' min='.$kill_list[$i].
			   ' count='.$sukill->{_count}.
			   ' \\'.$newline;
    }
    $sukill->{_Steps} = $sukill->{_Steps};
    return $sukill->{_Steps};
}

   
=head2 sub get_max_index

max index = number of input variables -1

=cut

 sub get_max_index {
 	my ($self) = @_;
 	# only file_name : index=6
 	my $max_index = 6;
 	
 	return($max_index);
 }



1;
