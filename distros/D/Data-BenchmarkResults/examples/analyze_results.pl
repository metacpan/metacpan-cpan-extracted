#!/usr/bin/perl -w

use Data::BenchmarkResults;
use strict;	

# This processes IOZone results files and compares two sets of runs (such as one filesystem against another)
# It requires iozone to have been set up to output data for Excel - this creates easily parse-able test result blocks

my $nojournal_results_object = new Data::BenchmarkResults;
my $journal_results_object = new Data::BenchmarkResults;

my $calc = "max";
my $filesystem1 = "hfsplus";
my $filesystem2 = "hfs";


my @files = @ARGV;


print "Testing $filesystem1 vs $filesystem2 w/ the best of ". (scalar @files)/2 . " runs\n";
print `uname -v`;
print scalar localtime() . "\n";

# Roll though each of the result files, adding the results to the result object.

while (my $current_file = shift @files)
{
	print "Current file: $current_file\n";
	unless (open(CURRENT_FILE, $current_file)) {warn "Can't open $current_file: $!\n"; next;}
	while (defined($_ = <CURRENT_FILE>))
{
		
chomp;

if (/Excel output is below\:/ .. eof())
	{
		
	if (/\"Writer report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Writer",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Writer",$current_file,\@data);
			}
		}
	if (/\"Re-writer report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Re-writer",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Re-writer",$current_file,\@data);
			}
		}
	if (/\"Reader report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Reader",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Reader",$current_file,\@data);
			}
		}
	if (/\"Re-Reader report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Re-Reader",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Re-Reader",$current_file,\@data);
			}
		}
	if (/\"Random read report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Random read",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Random read",$current_file,\@data);
			}
		}
	if (/\"Random write report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Random write",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Random write",$current_file,\@data);
			}
		}
	if (/\"Backward read report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Backward read",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Backward read",$current_file,\@data);
			}
		}
	if (/\"Record rewrite report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Record rewrite",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Record rewrite",$current_file,\@data);
			}
		}
	if (/\"Stride read report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Stride read",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Stride read",$current_file,\@data);
			}
		}
	if (/\"Fwrite report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Fwrite",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Fwrite",$current_file,\@data);
			}
		}
	if (/\"Re-Fwrite report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Re-Fwrite",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Re-Fwrite",$current_file,\@data);
			}
		}
	if (/\"Fread report/ .. /^$/)
		{
		my @writer_results = ();
		my @data = split(/\s+/,$_);
		@data = trim(@data);
		push (@writer_results,[@data]);
		if ($current_file =~ /\-$filesystem1\-/)
			{
			$nojournal_results_object->add_result_set("Fread",$current_file,\@data);
			}
		else
			{
			$journal_results_object->add_result_set("Fread",$current_file,\@data);
			}
		}


	}
}
}

$journal_results_object->process_all_result_sets($calc,0);
$nojournal_results_object->process_all_result_sets($calc,0);


# print out the processed (usually averaged) data from the runs for all tests

print "\n---------$filesystem1---------\n";


$nojournal_results_object->print_calculated_sets;


print "---------$filesystem2---------\n";


$journal_results_object->print_calculated_sets;


print "\n############### ----- ##############\n";


print "Comparing results.... Results are percentage throughput change from $filesystem1 to $filesystem2 (i.e.: $filesystem2 is x% faster/slower than $filesystem1)\n\n";


my $total_comparison = $journal_results_object->compare_all_result_sets($nojournal_results_object);

foreach my $test (keys %$total_comparison)
	{
		print "Test: $test\n\n";
		for my $i (0 .. $#{$total_comparison->{$test}})
		{
		for my $j (0 .. $#{$total_comparison->{$test}->[$i]})
			{print "$total_comparison->{$test}->[$i][$j]\t";}
		print "\n";
		}
	}


sub trim {
	my @out = @_;
	for (@out) {
		s/^\s+//;
		s/\s+$//;
	}
	return wantarray ? @out : $out[0];
}
