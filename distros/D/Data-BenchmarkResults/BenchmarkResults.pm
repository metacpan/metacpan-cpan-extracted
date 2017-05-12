package Data::BenchmarkResults;

require 5.005_62;
use strict;
use warnings;

use Statistics::Lite qw(:all);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::BenchmarkResults ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

sub new
{
	my $class = shift;
	my $self = {};
	bless($self,$class);
	return $self;
}
	
sub add_result_set
{
	my $self = shift;
	my $test_name = shift;
	my $file_name = shift;
	my $result_set = shift;
	push (@{$self->{test_results}{$test_name}{$file_name}},$result_set);
}

sub add_computed_set
{
	my $self = shift;
	my $test_name = shift;
	my $result_set = shift;
	push (@{$self->{computed_results}{$test_name}},@$result_set);
	
}


sub process_result_set
{
	my $self = shift;
	my $test_name = shift;
	my $process = shift;
	my $tossextremes = shift;
	
	my @computed = ();
	
	my @runs = values %{$self->{test_results}{$test_name}};
	
	
	for my $row (0 .. $#{$runs[0]})

	{	
		for my $column (0 .. $#{$runs[0][$row]})
		{ # iterate through the columns of each row
		
		my @rowvalues = ();
		
		for my $run (0 .. $#runs)
		{
			my $cleaned = $runs[$run][$row][$column];
			$cleaned =~ s/^\s+//;
			$cleaned =~ s/\s+$//;
			push @rowvalues, $cleaned;
		}
		
			if ($tossextremes == 1)

				{
				(my $max, my $maxlocation) = Max_with_Index(\@rowvalues);
				splice(@rowvalues,$maxlocation,1);
				(my $min, my $minlocation) = Min_with_Index(\@rowvalues);
				splice(@rowvalues,$minlocation,1);
				}
					
			if ($rowvalues[0] =~ /^\d+$/)
				{
						no strict 'refs'; 
						$computed[$row][$column] = &$process(@rowvalues);
				}
			else {$computed[$row][$column] = $rowvalues[0];}
		}

	}
	$self->add_computed_set($test_name,\@computed);
	return @computed;
}


sub process_all_result_sets
{
	my $self = shift;
	my $process = shift;
	my $tossextremes = shift;
	
	
	foreach my $test_name (keys %{$self->{test_results}})
	{
	my @computed = ();
	my @runs = values %{$self->{test_results}{$test_name}};
	
	
	for my $row (0 .. $#{$runs[0]})

	{	
		for my $column (0 .. $#{$runs[0][$row]})
		{ # iterate through the columns of each row
		
		my @rowvalues = ();
		
		for my $run (0 .. $#runs)
		{
			my $cleaned = $runs[$run][$row][$column];
			$cleaned =~ s/^\s+//;
			$cleaned =~ s/\s+$//;
			push @rowvalues, $cleaned;
		}
		

					
			if ($rowvalues[0] =~ /^\d+$/)
				{
				if ($tossextremes == 1)
						{
						(my $max, my $maxlocation) = Max_with_Index(\@rowvalues);
						splice(@rowvalues,$maxlocation,1);
						(my $min, my $minlocation) = Min_with_Index(\@rowvalues);
						splice(@rowvalues,$minlocation,1);
						}
					no strict 'refs'; 
					$computed[$row][$column] = &$process(@rowvalues);
				}
			else {$computed[$row][$column] = $rowvalues[0];}
		}

	}
	$self->add_computed_set($test_name,\@computed);
	}
	return 1;
}

sub compare_result_set
{
	my $self = shift;
	my $second_results = shift;
	my $test_name = shift;
	
	my @runs = ();
	my @computed = ();	
	
	push (@runs,$self->{computed_results}{$test_name});
	push (@runs,$second_results->{computed_results}{$test_name});
	
	for my $row (0 .. $#{$runs[0]})

	{	
		for my $column (0 .. $#{$runs[0][$row]})
		{ # iterate through the columns of each row
		
		my @rowvalues = ();
		
		for my $run (0 .. $#runs)
		{
			push @rowvalues, $runs[$run][$row][$column];
		}			
			if (($rowvalues[0] =~ /^\d+\.*\d*$/) && ($rowvalues[0] >0)){ $computed[$row][$column] = Percentage_difference($rowvalues[0],$rowvalues[1]);}
			else 
			{
			$computed[$row][$column] = $rowvalues[0];
			}

		}

	}
	
	return \@computed;
}

sub compare_all_result_sets
{
	my $self = shift;
	my $second_results = shift;
	my $test_name = shift;
	
	my %compared_tests = ();

	foreach my $test_name (keys %{$self->{test_results}})
	{
	my @runs = ();
	my @computed = ();
	
	push (@runs,$self->{computed_results}{$test_name});
	push (@runs,$second_results->{computed_results}{$test_name});
	
	for my $row (0 .. $#{$runs[0]})

		{	
			for my $column (0 .. $#{$runs[0][$row]})
			{ # iterate through the columns of each row
			
			my @rowvalues = ();
			
			for my $run (0 .. $#runs)
			{
				push @rowvalues, $runs[$run][$row][$column];
			}			
				if (($rowvalues[0] =~ /^\d+\.*\d*$/) && ($rowvalues[0] >0)){ $computed[$row][$column] = Percentage_difference($rowvalues[0],$rowvalues[1]);}
				else 
				{
				$computed[$row][$column] = $rowvalues[0];
				}
	
			}
			
		}
	$compared_tests{$test_name} = \@computed;
	}
	
	return \%compared_tests;
}

sub print_calculated_sets
{
	my $self = shift;
	
	for my $key (keys %{$self->{computed_results}})
		{
		print "Test=$key\n";
		for my $i (0 .. $#{$self->{computed_results}{$key}})
			{
			for my $j (0 .. $#{$self->{computed_results}{$key}->[$i]})
				{print "$self->{computed_results}{$key}->[$i][$j]\t";}
			print "\n";
			}
		}
	print "\n";
}

sub Max_with_Index {
    # takes an array ref - returns the max

    my $list = shift;
    my $max = $list->[0];
    my $ind = 0; # new
    my $i   = 0; # new
    foreach (@$list) {
        if ($_ > $max) {
           $max = $_;
           $ind = $i; # new
        }
        $i++; # new
    }

    return($max, $ind);
}

sub Min_with_Index {
    # takes an array ref - returns the min

    my $list = shift;
    my $min = $list->[0];
    my $ind = 0; # new
    my $i   = 0; # new
    foreach (@$list) {
        if ($_ < $min) {
           $min = $_;
           $ind = $i; # new
        }
        $i++; # new
    }

    return($min, $ind);
}

sub Percentage_difference #Takes two values and returns the relative percentage difference of the second from the first
{
my $first = shift;
my $second = shift;

my $absolute_change = $first-$second;
my $relative_change = $absolute_change/$second;
my $percentage = $relative_change * 100;
return $percentage;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Data::BenchmarkResults - Perl extension for averaging and comparing multiple benchmark runs.

=head1 SYNOPSIS

  use Data::BenchmarkResults;
  $conditionA_results = new Data::BenchmarkResults;
  $conditionB_results = new Data::BenchmarkResults;
  
  #Load test result runs for the first condition
  $conditionA_results->add_result_set("test1","run1",\@data1);
  $conditionA_results->add_result_set("test2","run1",\@data2);
  $conditionA_results->add_result_set("test1","run2",\@data3);
  $conditionA_results->add_result_set("test2","run2",\@data4);
  
  #Load test result runs for the second condition
  $conditionB_results->add_result_set("test1","run1",\@data5);
  $conditionB_results->add_result_set("test2","run2",\@data6);
  $conditionB_results->add_result_set("test1","run1",\@data7);
  $conditionB_results->add_result_set("test2","run2",\@data8);
  
  #Average (mean average) the results of all the the runs of 'test1'
  # w/o tossing the highest and lowest values (replace the '0' with '1'to
  # toss the highest and lowest values
  
  my $computed = $conditionA_results->process_result_set("test1","mean",0);
  my $computed2 = $conditionB_results->process_result_set("test1","mean",0);
  
  #OR process all of the tests at once (tossing the highest and lowest value) :
  
  $conditionA_results->process_all_result_sets("mean",1);
  $conditionB_results->process_all_result_sets("mean",1);


  #Print out all of the processed test results
  print "Condition A results.... \n\n"
  $conditionA_results->print_calculated_sets;
  print "Condition B results.... \n\n"
  $conditionB_results->print_calculated_sets;


  #Compare results of 'test1' of condition B against those with condition A
  # as a percentage change from A to B
  
  my $compared = $conditionB_results->compare_result_set($conditionA_results,"test1");

  #OR compare all the processed test results from one condition to those of another
  my $total_comparison = $conditionB_results->compare_all_result_sets($conditionA_results);



=head1 DESCRIPTION

new

add_result_set

add_computed_set

process_result_set

process_all_result_sets

compare_result_set

compare_all_result_sets

print_calculated_sets

=head2 EXPORT

None by default.


=head1 AUTHOR

Jason Titus, jasontitus@tiltastech.com

=head1 SEE ALSO

perl(1).

=cut
