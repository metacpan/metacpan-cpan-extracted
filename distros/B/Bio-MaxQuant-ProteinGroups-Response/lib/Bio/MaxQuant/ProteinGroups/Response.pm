package Bio::MaxQuant::ProteinGroups::Response;

use 5.006;
use strict;
use warnings FATAL => 'all';


use Carp;

use Statistics::Reproducibility;
use Text::CSV;
use IO::File;
use File::Path qw(make_path);
use Math::SigFigs;

our $SigFigs = 3;

=head1 NAME

Bio::MaxQuant::ProteinGroups::Response - Analyze MQ proteinGroups for differential responses

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This module is tailored for MaxQuant data, but could be applicable elsewhere.
The target experiment is one where several celltypes have been assayed for 
responses to different conditions, e.g. cancer cell lines responding to 
hormones and drugs.  The module help to analyse responses to the conditions
within each cell line and differences in those responses between cell lines.
Those differences in responses indicate that the proteins involved are markers
of the mechanism by which the cells differ in their response, and are therefore
not only good targets to exploit for biomarkers, but also for biological follow up.

    use Bio::MaxQuant::ProteinGroups::Response;

    my $resp = Bio::MaxQuant::ProteinGroups::Response->new(
    	filepath=>'proteinGroups.txt'
    );

    $resp->replicate_comparison(output_directory=>'./replicate_comparisons');
	$resp->calculate_response_comparisons(output_directory=>'./responses');
	$resp->calculate_differential_response_comparisons(output_directory=>'./differential_responses');

The data are output as tables in the directories.  They are the printable tables
returned from Statistics::Reproducibility.

=head1 SUBROUTINES/METHODS

=head2 new

creates a new ProteinGroups object.

Options: 
filepath - path to the file!  default is proteinGroups.txt
separator - NOT table separator! This is the separator 
used in the experiment name to separate cellline from 
condition from replicate.  Default is full stop (period)
rseparator - used for separating the compared cells/conditions.
the default is hyphen (-)
replicate_indicator - used in differential response comparisons
to indicate which cell the individual replicates were compared
(with the median of the other cell)

=cut

sub new {
	my $p = shift;
	my $c = ref($p) || $p;
	my %defaults = (
		filepath => 'proteinGroups.txt',
		separator => '.',
		rseparator => '-',
		replicate_indicator => '•',
		resultsfile => '',
	);
	my %opts = (%defaults, @_);

	my $o = {%opts};
	bless $o, $c;

	my $io = IO::File->new($opts{filepath}, 'r') 
		or die "Could not read $opts{filepath}: $!";
	my $csv = Text::CSV->new({sep_char=>"\t"});
	my $colref = $csv->getline($io);
	$csv->column_names (@$colref);

	$o->{csv} = $csv;
	$o->{io} = $io;
	$o->{header} = $colref;
	$o->{median_exclude} = [];
	return $o;
}

=head2 resultsfile

returns a handle to the results file, ready for writing.

this is not callde until processing starts, but when it is
it will clobber the old file.

=cut

sub resultsfile {
	my $o = shift;
	return unless $o->{resultsfile};
	return $o->{resultsfile_io} if exists $o->{resultsfile_io};

	$o->{resultsfile_io} = IO::File->new($o->{resultsfile},'w')
		or die "Could not write $o->{resultsfile}: $!";

	return $o->{resultsfile_io};
}

=head2 experiments

Returns the list of experiments in the file as a hash.
Keys are names, values are listrefs of cellline,condition,replicate.
Caches! So once called, it will not re-read the file
unless/until you delete $o->{experiments}

Also populates cellines, conditions and replicates lists, which are
accessible by their own accessors.

=cut

sub experiments {
	my $o = shift;
	# figure out experiment, unless already done...
	if(exists $o->{experiments}){
		return %{$o->{experiments}};
	}
	my @header = @{$o->{header}};
	my %celllines = ();
	my %conditions = ();
	my %replicates = ();
	my %condition_replicates = ();
	my %expts = ();
	foreach (@header){
		next unless /^Experiment\s(\S+)$/;
		my $expt = $1;
		my ($cell, $cond, $repl) = $o->parse_experiment_name($expt);
		return carp "bad experiment name format $_" unless 
			(defined $cell && defined $cond && defined $repl);
		$expts{$expt} = [$cell, $cond, $repl];
		$celllines{$cell} = 1;
		$conditions{$cond} = 1;
		$replicates{$repl} = 1;
		my $cc = $cell . $o->{separator} . $cond;
		$condition_replicates{$cc} = [] unless exists $condition_replicates{$cc};
		push @{$condition_replicates{$cc}}, $expt;
	}
	$o->{experiments} = \%expts;
	$o->{celllines} = [keys %celllines];
	$o->{conditions} = [keys %conditions];
	$o->{condition_replicates} = {%condition_replicates};
	$o->{replicates} = [keys %replicates];
	return %expts;
}

=head2 quickNormalize

TO BE REMOVED

Does a quick normalization of ALL the input columns.  They are each normalized
by their own median, and not directly to each other.

Two options are available: 

	select => [list of indices]
	exclude => [list of indices]

Select allows to choose a particular subset of rows on which to normalize, e.g. some
proteins you know don't change.
Exclude allows to choose a particular subset of rows to exclude from the
normalization, e.g. contaminants.


sub quickNormalize {
	my ($o,%opts) = @_;
	my $d = $o->data;
	my $n = $o->{n};
	my @I = (0..$n-1);
	if($opts{exclude}){
		my %I;
		@I{@I} = @I;
		delete $I{$_} foreach @{$opts{exclude}};
		@I = sort {$a <=> $b} keys %I;
	}
	if($opts{select}){
		@I = @{$opts{select}};
	}
	$o->{quicknorm} = {
		map {
			my $med = median ((@{$d->{$_}})[@I]);
			($_ => [map {/\d/ ? $_ - med : ''} @{$d->{$_}}])
		} 
		keys %$d;
	}
}

TO BE REMOVED

=cut



=head2 blankRows

Option: select (as for quick Normalize)

This allows blanking the data for a subset (e.g. contaminants) so that they do not
contribute to the statistics.



=cut

sub blankRows {
	my ($o,%opts) = @_;
	my $d = $o->data;
	my $n = $o->{n};
	my @I = @{$opts{select}};
	foreach my $k(keys %$d){
		blankItems($d->{$k}, @I);
	}
}

=head2 blankItems

help function, accepts a listref and a list of indices to blank (set to '')
returns the listref for your convenience.


=cut

sub blankItems {
	my ($listref,@I) = @_;
	foreach my $i(@I){
		$listref->[$i] = '';
	}
	return $listref;
}


=head2 celllines

Returns the list of cell lines.  Ensures experiments() is called.

=cut

sub celllines {
	my $o = shift;
	$o->experiments; # just make sure it's been called!
	return @{$o->{celllines}};
}

=head2 conditions

Returns the list of conditions.  Ensures experiments() is called.

=cut

sub conditions {
	my $o = shift;
	$o->experiments; # just make sure it's been called!
	return @{$o->{conditions}};
}

=head2 condition_replicates

Returns a hash of key=conditions, value=list of replicates.
Ensures experiments() is called.

=cut

sub condition_replicates {
	my $o = shift;
	$o->experiments; # just make sure it's been called!
	return %{$o->{condition_replicates}};
}

=head2 replicates

Returns the list of replicates.  Ensures experiments() is called.

=cut

sub replicates {
	my $o = shift;
	$o->experiments; # just make sure it's been called!
	return @{$o->{replicates}};
}

=head2 parse_experiment_name

Method  to parse the experiment name.
Uses $o->{separator} to separate into 3 parts.  Uses index and
substr, not regexes.  Default separator is dot/fullstop/period "." .

=cut

sub parse_experiment_name {
	my $o = shift;
	my $expt = shift;
	my $dot1 = index($expt, $o->{separator});
	my $dot2 = index($expt, $o->{separator}, $dot1 + 1);
	my $cell = substr($expt,0,$dot1);
	my $cond = substr($expt,$dot1+1, $dot2-$dot1-1);
	my $repl = substr($expt, $dot2+1);
	return ($cell,$cond,$repl);
}

=head2 parse_response_name

Method  to parse the response name.
Uses $o->{rseparator} to separate into 3 parts.  Uses index and
substr, not regexes.  Default separator is hyphen "-", which
should not be used in experiment name!

=cut

sub parse_response_name {
	my $o = shift;
	my $expt = shift;
	my $dot1 = index($expt, $o->{separator});
	my $dot2 = index($expt, $o->{rseparator}, $dot1 + 1);
	my $cell = substr($expt,0,$dot1);
	my $cond1 = substr($expt,$dot1+1, $dot2-$dot1-1);
	my $cond2 = substr($expt, $dot2+1);
	return ($cell,$cond1,$cond2);
}


=head2 replicate_comparison 

Uses Statistics::Reproducibility to get normalized values and
metrics on each condition.

Caches!

=cut

sub replicate_comparison {
	my $o = shift;
	my %opts = (
		output_directory => '',
		@_
	); 
	if($opts{output_directory}){
		make_path($opts{output_directory}) unless -d $opts{output_directory};
	}

	if(exists $o->{replicate_comparison}){
		return $o->{replicate_comparison};
	}
	my $data = $o->data;
	my %cr = $o->condition_replicates;
	$o->{replicate_comparison} = {};
	my $depth = -1;
	foreach my $cr(keys %cr){
		print STDERR "Processing $cr...\n";
		my @cols = @{$cr{$cr}};
		my @mydata = map {$data->{$_}} @cols;
		my $results = Statistics::Reproducibility
	        ->new()
	        ->data(@mydata)
	        ->run()
	        ->printableTable($depth);
	    $o->{replicate_comparison}->{$cr} = $results;

	    $o->dump_results_table('replicates', $cr, $results, \@cols);

	    if($opts{output_directory}){
		    my $fo = new IO::File($opts{output_directory}.'/'.$cr.'.txt', 'w') 
		    	or die "Could not write $opts{output_directory}/$cr.txt: $!";
		    print STDERR "Writing $opts{output_directory}/$cr.txt...\n";
		    print $fo join("\t", @{$results->[0]})."\n";
		    my $table_length = 0;
		    foreach (@$results){ $table_length = @$_ if @$_ > $table_length; }
		    foreach my $i(0..$table_length-1){
		    	print $fo join("\t", map {
		    			defined $results->[$_]->[$i]
		    			? sigfigs($results->[$_]->[$i])
		    			: ''
		    		} (1..$#$results)
		    	)."\n";
		    }
		    close($fo);
		}
	}
	return $o->{replicate_comparison};
}


=head2 response_comparisons

Returns the list of comparisons that can be made between conditions
within each cell line, given the replicates available.

At least 2 replicates must be available for a comparison to be made.

Caches.

=cut 

sub response_comparisons {
	my $o = shift;
	if(exists $o->{response_comparisons}){
		return %{$o->{response_comparisons}};
	}
	my %expts = $o->experiments;
	my @expts = sort keys %expts;
	my $sep = $o->{separator};
	my $rsep = $o->{rseparator};
	my %comparisons = ();
	foreach my $i(0..$#expts-1){
		my $e1 = $expts[$i];
		my ($cell1,$cond1,$repl1) = @{$expts{$e1}};
		foreach my $j($i+1..$#expts){
			my $e2 = $expts[$j];
			my ($cell2,$cond2,$repl2) = @{$expts{$e2}};
			# we want same cell line
			next unless $cell2 eq $cell1;
			# and different condition
			next if $cond2 eq $cond1;
			my $comp_key = "$cell1$sep$cond1$rsep$cond2";
			# store them in a useful way...
			$comparisons{$comp_key} = {$cond1=>{},$cond2=>{}} 
				unless defined $comparisons{$comp_key};
			$comparisons{$comp_key}->{$cond2}->{$e2} = "$cell1$sep$cond1$rsep$cond2$repl2";
			$comparisons{$comp_key}->{$cond1}->{$e1} = "$cell1$sep$cond1$repl1$rsep$cond2";
		}
	}
	$o->{response_comparisons} = \%comparisons;
	return %comparisons;
}


=head2 cell_comparisons

Returns the list of comparisons that can be made between cells
within each condition, given the replicates available.

At least 2 replicates must be available for a comparison to be made.

Caches.

=cut 

sub cell_comparisons {
	my $o = shift;
	if(exists $o->{cell_comparisons}){
		return %{$o->{cell_comparisons}};
	}
	my %expts = $o->experiments;
	my @expts = sort keys %expts;
	my $sep = $o->{separator};
	my $rsep = $o->{rseparator};
	my %comparisons = ();
	foreach my $i(0..$#expts-1){
		my $e1 = $expts[$i];
		my ($cell1,$cond1,$repl1) = @{$expts{$e1}};
		foreach my $j($i+1..$#expts){
			my $e2 = $expts[$j];
			my ($cell2,$cond2,$repl2) = @{$expts{$e2}};
			# we want same condition
			next unless $cond1 eq $cond1;
			# and different cell line
			next if $cell1 eq $cell2;
			my $comp_key = "$cell1$rsep$cell2$sep$cond2";
			# store them in a useful way...
			$comparisons{$comp_key} = {$cell1=>{},$cell2=>{}} 
				unless defined $comparisons{$comp_key};
			$comparisons{$comp_key}->{$cell2}->{$e2} = "$cell1$rsep$cell2$repl2$sep$cond1";
			$comparisons{$comp_key}->{$cell1}->{$e1} = "$cell1$repl1$rsep$cell2$sep$cond1";
		}
	}
	$o->{cell_comparisons} = \%comparisons;
	return %comparisons;
}

=head2 differential_response_comparisons 

Returns the list of comparisons that can be made between cell line
responses to a each condition.

Caches.

=cut

sub differential_response_comparisons {
	my $o = shift;
	if(exists $o->{differential_response_comparisons}){
		return %{$o->{differential_response_comparisons}};
	}
	my %rcs = $o->response_comparisons;
	my @rcs = sort keys %rcs;
	my %comparisons = ();
	foreach my $i(0..$#rcs-1){
		my $rc1 = $rcs[$i];
		my ($cell1, $cond1_1,$cond1_2) = $o->parse_response_name($rc1);
		foreach my $j($i+1..$#rcs){
			my $rc2 = $rcs[$j];
			my ($cell2, $cond2_1,$cond2_2) = $o->parse_response_name($rc2);
			next unless ($cond1_1 eq $cond2_1 && $cond1_2 eq $cond2_2)
					|| ($cond1_1 eq $cond2_2 && $cond1_2 eq $cond2_1);
			my $key = $cell1 . $o->{rseparator} . $cell2
				. $o->{separator} . $cond1_1 . $o->{rseparator} . $cond1_2;
			$comparisons{$key} = {$rc1=>$cell1, $rc2=>$cell2};
		}
	}
	$o->{differential_response_comparisons} = \%comparisons;
	return %comparisons;
}

=head2 data

Reads in all the protein ratios from the proteinGroups file.
Also reads other identifying information, such as id and Leading 
Proteins.  Reads each non-normalized ratio column into a list and
stores them in a hash by experiment name.  

=cut

sub data {
	my $o = shift;
	if(exists $o->{data}){
		return $o->{data};
	}
	my ($csv,$io) = map {$o->{$_}} qw/csv io/;
	my %expts = $o->experiments;
	my @expts = sort keys %expts;
	$o->{data} = {map {($_=>[])} @expts};
	seek($io,0,0);
	$csv->getline($io); # make sure for sure we're at start of data
	my $size = (stat $o->{filepath})[7];
	my $count = 0;
	while(! eof($io)){
		my $hr = $csv->getline_hr($io);
		foreach(@expts){
			push @{$o->{data}->{$_}}, $o->datum($hr->{"Ratio H/L $_"});
		}
		my $pos = tell($io);
		print STDERR "\r$pos/$size";
		$count ++;
	}
	print STDERR "\n";
	$o->{n} = $count;
	return $o->{data};
}

=head2 datum

Converts one datum into a logged ratio or an empty string, depending.

=cut

sub datum {
	my ($o,$d) = @_;
	if($d =~ /\d/){
		return log($d)/log(2);
	}
	else {
		return '';
	}
}

=head2 calculate_response_comparisons 

calculates the differences between conditions in a cell type.
outputs a bunch of files.  You can specify the diretory with 
output_directory option.

=cut

sub calculate_response_comparisons {
	my $o = shift;
	my %opts = (
		output_directory => '',
		@_);

	if($opts{output_directory}){
		make_path($opts{output_directory}) unless -d $opts{output_directory};
	}
	my %rcs = $o->response_comparisons;
	my @rcs = sort keys %rcs;
	# so, here for this protein, we calculate the comparisons
	# for everything... first we need to log, and then subtract...
	# this does mean that we need to normalize here independent
	# of the Statistics::Reproducibility thing (or hijack it)

	my %cfmedians = ();
	my %comparisons = ();

	foreach my $cf(@rcs){ # each comparison
		my ($cell,@crap) = $o->parse_experiment_name($cf);
		my @conds = sort keys %{$rcs{$cf}};
		die "not two conditions!" unless @conds == 2;
		my ($cond1,$cond2) = @conds;
		my %counterpart = ($cond1=>$cond2, $cond2=>$cond1);
		# we will calculate condition replicate minus counterpart median
		my %sign = ($cond1=>1, $cond2=>-1);
		
		my %medians = $o->medians;
		my %reps1 = %{$rcs{$cf}->{$cond1}};
		my %reps2 = %{$rcs{$cf}->{$cond2}};
		my @column_names = sort((values %reps1),(values %reps2));
		my %columns = map {($_=>[])} (@column_names);

		$cfmedians{$cf} = [map {[]} 1..$o->{n}];

		my $data = $o->{normalized};
		# we'll take the median of each protein here

		my $sign = 0;
		foreach my $cond(sort keys %{$rcs{$cf}}){ # each of the two conditions... sorted by name
			my $sign = $sign{$cond};
			my $counterpart = $counterpart{$cond}; 
			my $sep = $o->{separator};
			#my $cc = "$cell$sep$cond";
			my $ccc = "$cell$sep$counterpart";
			#print STDERR "$cc : $ccc : \n";
			my %reps = %{$rcs{$cf}->{$cond}};  # these are the replicates in this condition
			foreach my $r(sort keys %reps){ # replicates
				my $key = $reps{$r};
				#print STDERR "   : $r : $key \n";
				foreach my $i(0..$o->{n}-1){ # each protein... check enough data
					if(
						#defined $data->{$r}->[$i] && 
						$data->{$r}->[$i] ne '' 
						#&& defined $medians{$ccc}->[$i] 
						&& $medians{$ccc}->[$i] ne ''){
						# now these are sorted, so we do $cond-$replicate for 
						my $value = 
							$sign * ($data->{$r}->[$i] - $medians{$ccc}->[$i]);
						push @{$columns{$key}}, $value;
						# collect the values to make medians later...
						push @{$cfmedians{$cf}->[$i]}, $value;
					}
					else {
						push @{$columns{$key}}, '';
					}
				}
			}
		}
		# 
		foreach my $i(0..$o->{n}-1){ # each protein... check enough data
			if(@{$cfmedians{$cf}->[$i]} < 2){
				$cfmedians{$cf}->[$i] = '';
			}
			else {
				$cfmedians{$cf}->[$i] = median(@{$cfmedians{$cf}->[$i]});
			}
		}
		$o->{response_comparison_medians} = \%cfmedians;
		#
		%comparisons = (%comparisons, %columns);

		print STDERR "Processing $cf...\n";
		my @mydata = map {$columns{$_}} @column_names;
		#print Dumper @mydata;
		my $depth = -1;
		my $results = Statistics::Reproducibility
	        ->new()
	        ->data(@mydata)
	        ->run()
	        ->printableTable($depth);

	    #$o->{replicate_comparison}->{$cf} = $results;
	    $o->dump_results_table('responses', $cf, $results, \@column_names);

	    if($opts{output_directory}){
			my $fo = IO::File->new("$opts{output_directory}/$cf.txt",'w') 
				or die "Could not write $opts{output_directory}/$cf.txt: $!";
			print STDERR "Writing $opts{output_directory}/$cf.txt...\n";
		    print $fo join("\t", @{$results->[0]})."\n";
		    my $table_length = 0;
		    foreach (@$results){ $table_length = @$_ if @$_ > $table_length; }
		    foreach my $i(0..$table_length-1){
		    	print $fo join("\t", map {
		    			defined $results->[$_]->[$i]
		    			? sigfigs($results->[$_]->[$i])
		    			: ''
		    		} (1..$#$results)
		    	)."\n";
		    }
		    close($fo);
		}
	}
	$o->{response_comparison_results} = \%comparisons;

}

=head2 calculate_cell_comparisons 

calculates the differences between cell types in a condition.
outputs a bunch of files.  You can specify the diretory with 
output_directory option.

=cut

sub calculate_cell_comparisons {
	my $o = shift;
	my %opts = (
		output_directory => '',
		@_);

	if($opts{output_directory}){
		make_path($opts{output_directory}) unless -d $opts{output_directory};
	}
	my %rcs = $o->cell_comparisons;
	my @rcs = sort keys %rcs;


	# so, here for this protein, we calculate the comparisons
	# for everything... first we need to log, and then subtract...
	# this does mean that we need to normalize here independent
	# of the Statistics::Reproducibility thing (or hijack it)

	my %cfmedians = ();
	my %comparisons = ();

	foreach my $cf(@rcs){ # each comparison
		my ($cell,$cond,$rep) = $o->parse_experiment_name($cf.'.');

		my @cells = sort keys %{$rcs{$cf}};

		die "not two cells!" unless @cells == 2;
		my ($cell1,$cell2) = @cells;
		my %counterpart = ($cell1=>$cell2, $cell2=>$cell1);
		# we will calculate cell replicate minus counterpart median
		my %sign = ($cell1=>1, $cell2=>-1);
		
		my %medians = $o->medians;
		my %reps1 = %{$rcs{$cf}->{$cell1}};
		my %reps2 = %{$rcs{$cf}->{$cell2}};
		my @column_names = sort((values %reps1),(values %reps2));
		my %columns = map {($_=>[])} (@column_names);

		$cfmedians{$cf} = [map {[]} 1..$o->{n}];

		my $data = $o->{normalized};
		# we'll take the median of each protein here

		my $sign = 0;
		foreach my $cell(sort keys %{$rcs{$cf}}){ # each of the two cells... sorted by name
			my $sign = $sign{$cell};
			my $counterpart = $counterpart{$cell}; 
			my $sep = $o->{separator};
			#my $cc = "$cell$sep$cond";
			my $ccc = "$counterpart$sep$cond";
			#print STDERR "$cc : $ccc : \n";
			my %reps = %{$rcs{$cf}->{$cell}};  # these are the replicates in this cell
			foreach my $r(sort keys %reps){ # replicates
				my $key = $reps{$r};
				#print STDERR "   : $r : $key \n";
				foreach my $i(0..$o->{n}-1){ # each protein... check enough data
					if(
						defined $data->{$r}->[$i] && 
						$data->{$r}->[$i] ne '' 
						&& defined $medians{$ccc}->[$i] 
						&& $medians{$ccc}->[$i] ne ''){
						# now these are sorted, so we do $cond-$replicate for 
						my $value = 
							$sign * ($data->{$r}->[$i] - $medians{$ccc}->[$i]);
						push @{$columns{$key}}, $value;
						# collect the values to make medians later...
						push @{$cfmedians{$cf}->[$i]}, $value;
					}
					else {
						push @{$columns{$key}}, '';
					}
				}
			}
		}
		# 
		foreach my $i(0..$o->{n}-1){ # each protein... check enough data
			if(@{$cfmedians{$cf}->[$i]} < 2){
				$cfmedians{$cf}->[$i] = '';
			}
			else {
				$cfmedians{$cf}->[$i] = median(@{$cfmedians{$cf}->[$i]});
			}
		}
		$o->{cell_comparison_medians} = \%cfmedians;
		#
		%comparisons = (%comparisons, %columns);

		print STDERR "Processing $cf...\n";
		my @mydata = map {$columns{$_}} @column_names;
		#print Dumper @mydata;
		my $depth = -1;
		my $results = Statistics::Reproducibility
	        ->new()
	        ->data(@mydata)
	        ->run()
	        ->printableTable($depth);

	    #$o->{replicate_comparison}->{$cf} = $results;
	    $o->dump_results_table('celldiffs', $cf, $results, \@column_names);

	    if($opts{output_directory}){
			my $fo = IO::File->new("$opts{output_directory}/$cf.txt",'w') 
				or die "Could not write $opts{output_directory}/$cf.txt: $!";
			print STDERR "Writing $opts{output_directory}/$cf.txt...\n";
		    print $fo join("\t", @{$results->[0]})."\n";
		    my $table_length = 0;
		    foreach (@$results){ $table_length = @$_ if @$_ > $table_length; }
		    foreach my $i(0..$table_length-1){
		    	print $fo join("\t", map {
		    			defined $results->[$_]->[$i]
		    			? sigfigs($results->[$_]->[$i])
		    			: ''
		    		} (1..$#$results)
		    	)."\n";
		    }
		    close($fo);
		}
	}
	$o->{cell_comparison_results} = \%comparisons;

}


=head2 sigfigs

Helper function
Tries FormatSigFigs($_[0],$SigFigs), but only if $_[0] actually looks like a number!
$SigFigs is a global in this module and is set to 3.

=cut

sub sigfigs {
	my $x = shift;
	if($x =~ /^[-\.\d]+$/){
		if($x<1000){
			return FormatSigFigs($x,$SigFigs);
		}
		else {
			return int($x);
		}
	}
	else {
		return $x;
	}
}

=head2 calculate_differential_response_comparisons



=cut

sub calculate_differential_response_comparisons {
	my $o = shift;
	my %opts = (
		output_directory => '',
		@_);

	if($opts{output_directory}){
		make_path($opts{output_directory}) unless -d $opts{output_directory};
	}
	my %rcs = $o->response_comparisons;
	my %drcs = $o->differential_response_comparisons;
	my %rcms = %{$o->{response_comparison_medians}};
	my @rcs = sort keys %rcs;
	my @drcs = sort keys %drcs;
	# so, here for this protein, we calculate the comparisons
	# for everything... first we need to log, and then subtract...
	# this does mean that we need to normalize here independent
	# of the Statistics::Reproducibility thing (or hijack it)

	# and now the next bit... :-S

	# here we need to get use the response comparisons, and so need to 
	# look up the keys in %rcs.

	my %response_comparison_results = %{$o->{response_comparison_results}};
	my %response_comparison_medians = %{$o->{response_comparison_medians}};

	my $sep = $o->{separator};
	my $rsep = $o->{rseparator};

	my %differentials = ();

	foreach my $cf(@drcs){ # each comparison
		my $rsepi = index($cf,$rsep);
		my $sepi = index($cf,$sep);
		my $cell1 = substr($cf,0,$rsepi);
		my $cell2 = substr($cf,$rsepi+1,$sepi-$rsepi-1);
		my @cells = ($cell1,$cell2);
		my %counterpart = ($cell1=>$cell2, $cell2=>$cell1);
		my %sign = ($cell1 => 1, $cell2 => -1);
		my $repind = $o->{replicate_indicator};
		my %key = ($cell1 => "$cell1$repind$rsep$cell2", $cell2 => "$cell1$rsep$cell2$repind");
		my $condcomp = substr($cf,$sepi+1);

		my @keys = ();

		foreach my $cell(@cells){
			my $counterpart = $counterpart{$cell};
			my $sign = $sign{$cell};
			my $cellcomp = "$cell$sep$condcomp";
			my $countercomp = "$counterpart$sep$condcomp";
			my @rcs = map {values %$_} values %{$rcs{$cellcomp}};
			my $cellkey = $key{$cell};
			# always cell1 - cell2, let's do reps - median
			foreach my $rc(@rcs){
				my $repcombo = substr($rc, index($rc,$sep)+1);
				my $key = "$cellkey$sep$repcombo";
				push @keys, $key;
				$differentials{$key} = [];
				foreach my $i(0..$o->{n}-1){
					my $cell_replicate = $o->{response_comparison_results}->{$rc}->[$i];
					my $counter_median = $o->{response_comparison_medians}->{$countercomp}->[$i];
					my $value = '';
					if($cell_replicate ne '' && $counter_median ne ''){
						$value = ($cell_replicate - $counter_median) * $sign;
					}
					push @{$differentials{$key}}, $value;
				}
			}
		}
		@keys = sort @keys;

		print STDERR "Processing $cf\n";
		my @mydata = map {$differentials{$_}} @keys;

		my $depth = -1;
		my $results = Statistics::Reproducibility
	        ->new()
	        ->data(@mydata)
	        ->run()
	        ->printableTable($depth);

	    #$o->{replicate_comparison}->{$cf} = $results;
	    $o->dump_results_table('differential_responses', $cf, $results, \@keys);

	    if($opts{output_directory}){
			my $fo = IO::File->new("$opts{output_directory}/$cf.txt",'w') 
				or die "Could not write $opts{output_directory}/$cf.txt: $!";
			print STDERR "Writing $opts{output_directory}/$cf.txt...\n";
		    print $fo join("\t", @{$results->[0]})."\n";
		    my $table_length = 0;
		    foreach (@$results){ $table_length = @$_ if @$_ > $table_length; }
		    foreach my $i(0..$table_length-1){
		    	print $fo join("\t", map {
		    			defined $results->[$_]->[$i]
		    			? sigfigs($results->[$_]->[$i])
		    			: ''
		    		} (1..$#$results)
		    	)."\n";
		    }
		    close($fo);
		}
	}
}

=head2 medians

calculates the medians for all replicate sets and stores them in 
$o->{medians}

=cut

sub medians {
	# this function has been manually verified

	my $o = shift;

	return %{$o->{medians}} if exists $o->{medians};
	my %opts = (exclude=>$o->{median_exclude},output_directory=>'',@_);
	if($opts{output_directory}){
		make_path($opts{output_directory}) unless -d $opts{output_directory};
	}
	# exclude => [indices]
	my @I = @{$opts{exclude}}; 

	my $data = $o->data;
	my %cr = $o->condition_replicates;
	my %medians = ();

	my @keys =  sort keys %$data;
	my $k = scalar @keys;
	my @mydata = map { blankItems([@{$data->{$_}}],@I)} @keys;

# here we have to do subtract medians...

	my $depth = -1;
	my $results = Statistics::Reproducibility
	        ->new()
	        ->data(@mydata)
	        ->subtractMedian()
	        ->printableTable($depth);

	#print Dumper $results;

	my @relevant_columns = (@$results)[3..$k+2]; # NEED TO SORT THIS OUT!

	my %normalized = ();
	@normalized{@keys} = @relevant_columns;
	$o->{normalized} = \%normalized;

	foreach my $i(0..$o->{n}-1){
		foreach my $cond(keys %cr){
			my @repkeys = @{$cr{$cond}};
			$medians{$cond}->[$i] = median ( map {$normalized{$_}->[$i]} @repkeys );
		}
	}
	$o->{medians} = \%medians;

	if($opts{output_directory}){
		print "Outputting to $opts{output_directory}...\n";
		dumpHashtable($opts{output_directory}.'/normalized.txt', $o->{normalized});
		dumpHashtable($opts{output_directory}.'/medians.txt', $o->{medians});
		print "Done\n";
	}
	if($o->resultsfile){
		print "Outputting to $o->{resultsfile}...\n";
		$o->put_resultsfile_hashtable('normalized','normalized',$o->{normalized});
		$o->put_resultsfile_hashtable('normalized','medians',$o->{medians});
		print "Done\n";
	}

	return %medians;
}

=head2 put_resultsfile_hashtable

a method called by medians() if resultsfile was defined.  Calls put_resultsfile with
some medians and normalized data.

=cut 

sub put_resultsfile_hashtable {
	my ($o,$section,$derivation,$ht) = @_;
	# HoL
 	$o->put_resultsfile(
 		[
 			map {
 				my @en = $o->parse_experiment_name($_);
 				my $en =  $en[1] 
 					? join($o->{separator}, @en[0..1])
 					: $_;
 				[	
					"n/s:$section/n:$en/d:$derivation/k:$_/t:$derivation/",	
					map {sigfigs($_)} @{$ht->{$_}}	
				]
 			} sort keys %$ht
 		]
 	);
}


=head2 dumpHashtable

helper function that dumps a HoL as a tab delimited table.

=cut

sub dumpHashtable {
	my ($fn,$hol) = @_;
	my $io = IO::File->new($fn, 'w') or die "Could not write $fn: $!";
	my @h = sort keys %$hol;
	my $L = 0;
	foreach (@h){
		my $l = scalar @{$hol->{$_}};
		$L = $l if $l > $L;
	} 
	print $io join("\t", @h)."\n";
	foreach my $i (0..$L-1){
		print $io join("\t", map {sigfigs($hol->{$_}->[$i])} @h)."\n";
	}
}


=head2 median

helper function that does a simple median calculation

=cut

sub median {
	my @x = sort {$a <=> $b} map { /\d/ ? $_ : () } @_; # strips non-numbers (ish)
	return '' if scalar(@x) < 2; # minumum is 2!
	if(@x % 2){ #odd
		return $x[scalar(@x) / 2]; # 0 1 2 3 4   @/2
	}
	else { # even
		return $x[(scalar(@x)-1) / 2] / 2
			+ $x[(scalar(@x)+1) / 2] / 2;# 0 1 2 3 4 5  (@-1)/2  , (@+1)/2
	}
}


=head2 put_resultsfile

take a list of lists (ref) and outputs directly to $o->{resultsfile}.
This is as an alternative or addition to the output_file options
avaiable for some methods, and is called by dump_results_table
and others throughout processing.

=cut

sub put_resultsfile {
	my ($o,$table) = @_;
	my $io = $o->resultsfile;
	if($io){
		print $io map {join("\t", @$_)."\n"} @$table;
	}
}

=head2 dump_results_table 

Dumps a results table to a file ($o->{complete_results_file})
for laster use.

=cut

sub dump_results_table {
	my ($o,$section,$name,$data,$keys) = @_;
	my @results = translate_results_table($section,$name,$data,$keys);
	$o->put_resultsfile(\@results);
}

=head2 translate_results_table 

helper function that separates out and better labels the different results from 
Statistics::Reproducbility

=cut

sub translate_results_table {
	my ($section,$name,$table,$keys) = @_;
	# headers we get are:
	# Column x (x is any number)
	# Regression, M, C (a list for columns)
	# Statistic, Value (a list for set of columns)
	# DerivedFrom (how the columns on the left were derived from those on the right)
	my @header = @{$table->[0]};
	my $DerivedFrom = 'source';
	my $compareColumn = 1;
	my $flag = '';
	my %compareFinder = ();
	my $i = @header;
	my @results = ();
	while($i>0){
		my $index = $i;
		my $row = $table->[$index];
		$i--;
		my $h = $header[$i];
		if($h =~ /^Column\s(\d+)$/){
			my $c = $1;
			my $j = $c - 1;
			my $newname = "n/s:$section/n:$name/d:$DerivedFrom/k:"
							.$keys->[$j]."/t:data/";
			$header[$i] = $newname;
			push @results, [$newname, map {sigfigs($_)} @$row];
			$compareFinder{$c} = $#results;
		}
		elsif($h eq 'DerivedFrom'){
			$DerivedFrom = $table->[$i+1]->[0];
			$flag = $DerivedFrom eq 'rotateToRegressionLine'
				? '*' : '';
		}
		elsif($h =~ /Regression/){
			my $M = $table->[$index+1];
			my $C = $table->[$index+2];
			foreach my $k(0..$#$row){
				my ($h,$m,$c) = map {$_->[$k]} ($row,$M,$C);
				if($h =~ /^Column\s(\d+)$/){
					my $j = $1 - 1;
					my $newname = "1/s:$section/n:$name/d:$DerivedFrom/k:".$keys->[$j];

					push @results, ["$newname/t:M/", sigfigs($m)];
					push @results, ["$newname/t:C/", sigfigs($c)];
				}
			}
		}
		elsif($h =~ /Statistic/){
			my $V = $table->[$index+1];
			foreach my $k(0..$#$row){
				my ($h,$v) = map {$_->[$k]} ($row,$V);
				my $newname = "1/s:$section/n:$name/d:$DerivedFrom/k:$name/t:$h/";
				if($h eq 'CompareColumn'){
					my @cc = @{$results[$compareFinder{$v}]};
					$v = shift @cc;
					push @results, [
						"n/s:$section/n:$name/d:$DerivedFrom/k:$name/t:spread/$flag",
						@cc
					];
				}
				push @results, [$newname, sigfigs($v)];
			}
		}
		elsif($h =~ /^M$|^C$|^Value$/){
			# ignore, because we've already collected it in Statistic or Regression.
		}
		else {
			my $thisflag = $h eq 'SpreadOverErrorPvalue' ? $flag : '';
			my $newname = "n/s:$section/n:$name/d:$DerivedFrom/k:"
							."$name/t:$h/$thisflag";
			push @results, [$newname, map {sigfigs($_)} @$row];
		}
	}
	return @results;
}








=head1 AUTHOR

Jimi, C<< <j at 0na.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-maxquant-proteingroups-response at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-MaxQuant-ProteinGroups-Response>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::MaxQuant::ProteinGroups::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-MaxQuant-ProteinGroups-Response>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-MaxQuant-ProteinGroups-Response>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-MaxQuant-ProteinGroups-Response>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-MaxQuant-ProteinGroups-Response/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jimi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Bio::MaxQuant::ProteinGroups::Response
