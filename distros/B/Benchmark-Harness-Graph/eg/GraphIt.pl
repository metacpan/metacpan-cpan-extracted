#!/usr/bin/perl -w
use Benchmark::Harness::Graph;
use strict;

	my ($filename, $analysisType, $asSchema) =
		( 't/benchmark.Trace.Graph.xml',
			'Graph',
			'Trace'
		);

	my $graphType = "Benchmark::Harness::$analysisType";
	my $graph = new $graphType($filename, 700, 350,
					{
						 'schema' => $asSchema
						,'x_legend'  => 'Time - secs', 'x_max_value'  => 0.4
						,'y1_legend' => 'Memory | MB', 'y1_max_value' => 40
						,'y2_legend' => 'CPU | %',     'y2_max_value' => 100
					});
	die $@ if $@;

    print "$analysisType in $graph->{outFilename}\n";

	$graph->{outFilename} =~ s{/}{\\}g if $^O eq 'MSWin32'; # Damn DOS!
	system($graph->{outFilename});