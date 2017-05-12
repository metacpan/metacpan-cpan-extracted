##########################################################
# AI::NNFlex::Dataset
##########################################################
# Dataset methods for AI::NNFlex - perform learning etc
# on groups of data
#
##########################################################
# Versions
# ========
#
# 1.0	20050115	CColbourn	New module
#
# 1.1	20050324	CColbourn	Added load support
#
##########################################################
# ToDo
# ----
#
#
###########################################################
#
use strict;
package AI::NNFlex::Dataset;


###########################################################
# AI::NNFlex::Dataset::new
###########################################################
sub new
{
	my $class = shift;
	my $params = shift;
	my $dataset;
	if ($class =~ /HASH/)
	{
		$dataset = $class;
		$dataset->{'data'} = $params;
		return 1;
	}

	my %attributes;
	$attributes{'data'} = $params;

	$dataset = \%attributes;
	bless $dataset,$class;
	return $dataset;
}


###########################################################
# AI::NNFlex::Datasets::run
###########################################################
sub run
{
	my $self = shift;
	my $network = shift;
	my @outputs;
	my $counter=0;

	for (my $itemCounter=0;$itemCounter<(scalar @{$self->{'data'}});$itemCounter +=2)
	{
		$network->run(@{$self->{'data'}}[$itemCounter]);
		$outputs[$counter] = $network->output();
		$counter++;
	}

	return \@outputs;

}

###############################################################
# AI::NNFlex::Dataset::learn
###############################################################
sub learn
{
	my $self = shift;
	my $network = shift;
	my $error;

	for (my $itemCounter=0;$itemCounter<(scalar @{$self->{'data'}});$itemCounter +=2)
	{
		$network->run(@{$self->{'data'}}[$itemCounter]);
		$error += $network->learn(@{$self->{'data'}}[$itemCounter+1]);
	}

	$error = $error*$error;

	return $error;
}

#################################################################
# AI::NNFlex::Dataset::save
#################################################################
# save a dataset in an snns .pat file
#################################################################
sub save
{
	my $dataset = shift;
	my %config = @_;

	open (OFILE,">".$config{'filename'}) or return "File error $!";

	print OFILE "No. of patterns : ".((scalar @{$dataset->{'data'}})/2)."\n";
	print OFILE "No. of input units : ".(scalar @{$dataset->{'data'}->[0]})."\n";
	print OFILE "No. of output units : ".(scalar @{$dataset->{'data'}->[1]})."\n\n";

	my $counter = 1;
	my @values = @{$dataset->{'data'}};
	while (@values)
	{
		print OFILE "# Input pattern $counter:\n";
		my $input = shift (@values); 
		my @array = join " ",@$input;
		print OFILE @array;
		print OFILE "\n";

		print OFILE "# Output pattern $counter:\n";
		my $output = shift(@values); 
		@array = join " ",@$output;
		print OFILE @array;
		print OFILE "\n";

		$counter++;
	}

	close OFILE;
	return 1;
}


#############################################################
# AI::NNFlex::Dataset::load
#############################################################
sub load
{
	my $dataset = shift;
	my %params = @_;

	my @data;

	my $filename = $params{'filename'};
	if (!$filename)
	{
		return "No filename specified";
	}

	open (IFILE,"$filename") or return "Unable to load $filename - $!";

	my %config;
	# snns pat files have a 3 line header, defining number of patterns &
	# number of input and output units
	my $counter =0;
	while ($counter <3)
	{
		my $line = <IFILE>;
		if ($line =~/^\n/ || $line =~/^#/){next}
		my ($tag,$value) = split/:/,$line;
		$tag=lc($tag);
		$tag =~s/ //g;
		
		$config{lc($tag)} = $value;
		$counter++;
	}

	my $filecontent;
	while (<IFILE>)
	{
		if($_ =~ /^#/ || $_ =~ /^\n/){next}
		$filecontent .= $_;
	}

	my @individualvals = split /\s+/s,$filecontent;

	for (my $offset=0;$offset<(scalar @individualvals);$offset+=($config{'no.ofinputunits'} + $config{'no.ofoutputunits'}))
	{
		my @input=@individualvals[$offset..($offset+$config{'no.ofinputunits'}-1)];
		push @data,\@input;
		if ($config{'no.ofoutputunits'} > 0)
		{
			my @output=@individualvals[($offset+$config{'no.ofinputunits'})..($offset+$config{'no.ofinputunits'}+$config{'no.ofoutputunits'}-1)];
			push @data,\@output;
		}
	}

		
	$dataset->new(\@data);

	return 1;
}
	
##########################################################
# AI::NNFlex::Dataset::add
##########################################################
# add an input/output pair to the dataset
##########################################################
sub add
{
	my $dataset= shift;
	my $params = shift;

	if (!$params){return "Nothing to add"};
	if ($params !~/ARRAY/){return "Need a reference to an array"}

	# support adding single patterns (for Hopfield type nets)
	if ($$params[0] !~ /ARRAY/)
	{
		push @{$dataset->{'data'}},$params;
	}
	else
	{
		push @{$dataset->{'data'}},$$params[0];
		push @{$dataset->{'data'}},$$params[1];
	}

	return 1;
}

##################################################################
# AI::NNFlex::Dataset::delete
##################################################################
# delete an item from the dataset by index
##################################################################
sub delete
{
	my $dataset = shift;
	my $index = shift;
	my @indexarray;

	if (!$index){return 0}

	if ($index =~ /ARRAY/)
	{
		@indexarray = @$index;
	}
	else
	{
		$indexarray[0] = $index;
	}

	my @newarray;
	my $counter=0;
	foreach (@indexarray)
	{
		unless ($counter == $_)
		{
			push @newarray,${$dataset->{'data'}}[$_];
		}
	}

	$dataset->{'data'} = \@newarray;

	return 1;
}



1;
=pod

=head1 NAME

AI::NNFlex::Dataset - support for creating/loading/saving datasets for NNFlex nets

=head1 SYNOPSIS

 use AI::NNFlex::Dataset;

 my $dataset = AI::NNFlex::Dataset->new([[0,1,1,0],[0,0,1,1]]);

 $dataset->add([[0,1,0,1],[1,1,0,0]]);

 $dataset->add([0,1,0,0]);

 $dataset->save(filename=>'test.pat');

 $dataset->load(filename=>'test.pat');

=head1 DESCRIPTION

This module allows you to construct, load, save and maintain datasets for use with neural nets implemented using the AI::NNFlex classes. The dataset consists of an array of references to arrays of data. Items may be added in pairs (useful for feedforward nets with an input & target pair of values) or individually (for Hopfield type nets where only an input is specified). The load and save methods use files that are compatible (I think) with SNNS .pat files.

=head1 CONSTRUCTOR 

=head2 AI::NNFlex::Dataset->new([[INPUT],[TARGET]]);

Parameters:

The constructor takes an (optional) reference to an array of one or more arrays. For convenience you can specify two values at a time (for INPUT and OUTPUT values) or a single value at a time. You can also leave the parameters blank, in which case the constructor creates a Dataset object with no values. Values can then be added with the 'add' method.       

The return value is an AI::NNFlex::Dataset object.

=head1 METHODS

This is a short list of the main methods implemented in AI::NNFlex::Dataset


=head2 add

 Syntax:

 $dataset->add([[INPUT],[OUTPUT]]);

or

 $dataset->add([VALUE]);

This method adds new values to the end of the dataset. You can specify the values as pairs or individually.

=head2 load

 Syntax:

 $dataset->load(filename=>'filename.pat');

Loads an SNNS type .pat file into a blank dataset. If called on an existing dataset IT WILL OVERWRITE IT!

=head2 save

 $dataset->save(filename=>'filename.pat');

Save the existing dataset as an SNNS .pat file. If the file already exists it will be overwritten.

=head2 delete

 $dataset->delete(INDEX);

or

 $dataset->delete([ARRAY OF INDICES]);

Deletes 1 or more items from the dataset by their index (counting from 0). Note that if you are using pairs of values (in a backprop net for example) you MUST delete in pairs - otherwise you will delete only the input/target, and the indices will be shifted leaving your dataset in a messed up state.

=head1 EXAMPLES

See the code in ./examples.


=head1 PREREQs

None.

=head1 SEE ALSO

 AI::NNFlex


=head1 TODO

Method to delete existing dataset entries by index

Method to validate linear separability of a dataset.

=head1 CHANGES


=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net



=cut

