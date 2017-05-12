#!/usr/local/bin/perl
use strict;
use Data::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Filesource;

use vars qw ($totxdep $totxsex $nemp $totgral);

sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;

	$sheet->MVPrint(0, 0,"-" x 70);
	$sheet->Move(0,1);
	$sheet->PrintC("Example using an ascii plain file");
	$sheet->MVPrint(60, 1,$report->date(1));
	$sheet->MVPrint(16, 2,"Information from file example2.dat");
	$sheet->MVPrint(0, 3,$report->time(1));
	$sheet->MVPrint(60, 3,"PAG : ".$report->page(1));
	$sheet->MVPrint(0, 4,"-" x 70);
}

sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(8, 0,"Name          Department     Telephone     Sex     Salary");
	$sheet->MVPrint(0, 1,"------------------- -------------- -------------- ----- --------------");
}

sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(0, 0, sprintf("%-20s", $rep_actline->[0]));
	$sheet->MVPrint(21, 0,$rep_actline->[3]);
	$sheet->MVPrintP(36, 0,$rep_actline->[2], "xx-xx-xx-xx");
	$sheet->MVPrintP(56, 0,$rep_actline->[4], '$$$,$$$,999.99');
	$sheet->MVPrintP(51, 0, $rep_actline->[1], " x ");
	$totxsex += $rep_actline->[4];
	$nemp++;
}

sub init_vars() {
	$totxdep    = 0.0;
	$totxsex    = 0.0;
	$nemp       = 0;
	$totgral    = 0.0;
}

sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(0, 1,"Grand Total : ");
	$sheet->MVPrintP(14, 1,$totgral, '$$$,$$$,999.99');
	$sheet->MVPrint(0, 2,"End of Report");
}

sub BREAK_1($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my $sex = "Male";
	$sex = "Female" if ($rep_actline->[1] eq "F");
	$sheet->MVPrint(0, 1,"Department");
	$sheet->MVPrint(0, 2,"Number of ");
	$sheet->MVPrint(10, 2,$sex);
	$sheet->MVPrintP(50, 2,$totxsex, '$$$,$$$,999.99');
	$sheet->MVPrint(23, 2,$nemp);
	$sheet->MVPrint(42, 2,"Total : ");
	$totxdep += $totxsex;
	$nemp     = 0;
	$totxsex  = 0.0;
}

sub BREAK_2($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	$sheet->MVPrint(44, 1,"= ");
	$sheet->MVPrint(0, 1,"Total from Department ");
	$sheet->MVPrintP(46, 1,$totxdep, '$$$,$$$,999.99');
	$sheet->MVPrint(22, 1,$rep_actline->[3]);
	$totgral += $totxdep;
	$totxdep  = 0;
	$report->newpage() unless ($report->eOR());
}

#main
{
	my %rep_breaks = ();
	$rep_breaks{1} = \&BREAK_1;
	$rep_breaks{3} = \&BREAK_2;
	my $source = new Data::Reporter::Filesource(File => "example2.dat");
	my $report = new Data::Reporter();
	$report->configure(
		Width	=> 70,
		Height	=> 66,
		SubFinal 	=> \&FINAL,
		Breaks	=> \%rep_breaks,
		SubHeader	=> \&HEADER,
		SubTitle	=> \&TITLE,
		SubDetail	=> \&DETAIL,
		Source	=> $source,
		File_name	=> "example4.out"
	);
	$report->generate();
}
