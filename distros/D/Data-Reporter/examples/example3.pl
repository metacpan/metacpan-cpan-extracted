#!/usr/local/bin/perl
use strict;
use Data::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Sybsource;
use vars qw ($elemstype $totaltypes);

sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(0, 0,"-" x 80);
	$sheet->Move(0,1);
	$sheet->PrintC("Example of use of Data::Reporter");
	$sheet->MVPrint(70, 1,$report->date(1));
	$sheet->Move(1,2);
	$sheet->PrintC("Output from query: select * from sysobjects (firts 100 records)");
	$sheet->Move(0,3);
	$sheet->PrintC(24, 3,"Program generated with VisRep.pl");
	$sheet->MVPrint(71, 3,"PAG : ".$report->page(1));
	$sheet->MVPrint(0, 3,$report->time(1));
	$sheet->MVPrint(0, 4,"-" x 80);
}

sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();

	$sheet->MVPrint(8, 0,"Name             Id        uid      type    userstat  sysstat  indexdel");
	$sheet->MVPrint(0, 1,"-------------------- --------- --------- --------- --------- --------- ---------");
}

sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(44, 0, $rep_actline->[3]);
	$sheet->MVPrint( 0, 0, substr($rep_actline->[0], 0, 20));
	$sheet->MVPrint(54, 0, $rep_actline->[4]);
	$sheet->MVPrint(74, 0, $rep_actline->[6]);
	$sheet->MVPrint(65, 0, $rep_actline->[5]);
	$sheet->MVPrint(21, 0, $rep_actline->[1]);
	$sheet->MVPrint(34, 0, $rep_actline->[2]);
	$elemstype++;
}

sub init_globals() {
	$elemstype  = 0;
	$totaltypes = 0;
}

sub FOOTER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(0, 0,"-" x 80);
	$sheet->MVPrint(0, 1,"This is a simple footer");
}

sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(0, 1,"There were ");
	$sheet->MVPrint(11, 1,$totaltypes);
	$sheet->MVPrint(15, 1,"number of types");
	$sheet->MVPrint(0, 2,"End of Report");
}

sub BREAK_1($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$report->newpage()unless $report->eOR();
	$sheet->MVPrintP(35, 1, "999", $elemstype);
	$sheet->MVPrint(0, 1,"Number of elements from type ");
	$sheet->MVPrint(29, 1, $rep_actline->[3]);
	$sheet->MVPrint(33, 1,": ");
	$elemstype =0;
	$totaltypes++;
}

#main
{
	init_globals();

	my %rep_breaks = ();
	$rep_breaks{3} = \&BREAK_1;
	my $source = new Data::Reporter::Sybsource(Arguments => \@ARGV,
		Query => 'use master
					set rowcount 100
					select * from sysobjects 
					order by type
				');
	my $report = new Data::Reporter();
	$report->configure(
		Width	=> 80,
		Height	=> 30,
		SubFooter	=> \&FOOTER,
		Footer_size	=> 2,
		SubFinal 	=> \&FINAL,
		Breaks	=> \%rep_breaks,
		SubHeader	=> \&HEADER,
		SubTitle	=> \&TITLE,
		SubDetail	=> \&DETAIL,
		Source	=> $source,
		File_name	=> "example3.out"
	);
	$report->generate();
}
