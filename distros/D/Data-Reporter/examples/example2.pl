#!/usr/local/bin/perl
#SIZE 70 66
#OUTPUTFILE example2.out
#SOURCE Filesource example2.dat
#SECTION: DEFAULT_USES 0
#CODE AREA
use strict;
use Data::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Filesource;
#END

#SECTION: USES 0
#CODE AREA
use vars qw ($totxdep $totxsex $nemp $totgral);
#END

#SECTION: HEADER 0
sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE ----------------------------------------------------------------------
	$sheet->MVPrint(0, 0,"----------------------------------------------------------------------");
#ORIG LINE                  Example using an ascii plain file          @D1
	$sheet->MVPrint(17, 1,"Example using an ascii plain file          ");
	$sheet->MVPrint(60, 1,$report->date(1));
#ORIG LINE                 Information from file example2.dat
	$sheet->MVPrint(16, 2,"Information from file example2.dat");
#ORIG LINE @T1                                                         @P1
	$sheet->MVPrint(0, 3,$report->time(1));
	$sheet->MVPrint(60, 3,"PAG : ".$report->page(1));
#ORIG LINE ----------------------------------------------------------------------
	$sheet->MVPrint(0, 4,"----------------------------------------------------------------------");
}
#END

#SECTION: TITLE 0
sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE         Name          Department     Telephone     Sex     Salary
	$sheet->MVPrint(8, 0,"Name          Department     Telephone     Sex     Salary");
#ORIG LINE ------------------- -------------- -------------- ----- --------------
	$sheet->MVPrint(0, 1,"------------------- -------------- -------------- ----- --------------");
}
#END

#SECTION: DETAIL 0
sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0] = sprintf("%-20s", $rep_actline->[0]);
$field[1] = $rep_actline->[3];
$field[2] = Data::Reporter::RepFormat::ToPicture($rep_actline->[2], "xx-xx-xx-xx");
$field[3] = " ".$rep_actline->[1]." ";
$field[4] = Data::Reporter::RepFormat::ToPicture($rep_actline->[4], '$$$,$$$,999.99');
$totxsex += $rep_actline->[4];
$nemp++;
#OUTPUT AREA
#ORIG LINE @F0                  @F1            @F2            @F3  @F4
	$sheet->MVPrint(0, 0,$field[0]);
	$sheet->MVPrint(36, 0,$field[2]);
	$sheet->MVPrint(56, 0,$field[4]);
	$sheet->MVPrint(21, 0,$field[1]);
	$sheet->MVPrint(51, 0,$field[3]);
}
#END

#SECTION: FUNCTIONS 0
#CODE AREA
sub init_vars() {
	$totxdep    = 0.0;
	$totxsex    = 0.0;
	$nemp       = 0;
	$totgral    = 0.0;
}
#END

#SECTION: FINAL 0
sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0] = Data::Reporter::RepFormat::ToPicture($totgral, '$$$,$$$,999.99');
#OUTPUT AREA
#ORIG LINE 
#ORIG LINE Grand Total : @F0
	$sheet->MVPrint(0, 1,"Grand Total : ");
	$sheet->MVPrint(14, 1,$field[0]);
#ORIG LINE End of Report
	$sheet->MVPrint(0, 2,"End of Report");
}
#END

#SECTION: BREAK_1 1
sub BREAK_1($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0] = "Male";
$field[0] = "Female" if ($rep_actline->[1] eq "F");
$field[1] = $nemp;
$field[2] = Data::Reporter::RepFormat::ToPicture($totxsex,'$$$,$$$,999.99');
$totxdep += $totxsex;
$nemp     = 0;
$totxsex  = 0.0;
#OUTPUT AREA
#ORIG LINE 
#ORIG LINE Department
	$sheet->MVPrint(0, 1,"Department");
#ORIG LINE Number of @F0          @F1                Total : @F2
	$sheet->MVPrint(0, 2,"Number of ");
	$sheet->MVPrint(10, 2,$field[0]);
	$sheet->MVPrint(50, 2,$field[2]);
	$sheet->MVPrint(23, 2,$field[1]);
	$sheet->MVPrint(42, 2,"Total : ");
#ORIG LINE 
#ORIG LINE 
}
#END

#SECTION: BREAK_2 3
sub BREAK_2($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0] = $rep_actline->[3];
$field[1] = Data::Reporter::RepFormat::ToPicture($totxdep, '$$$,$$$,999.99');
$totgral += $totxdep;
$totxdep  = 0;
$report->newpage() unless ($report->eOR());
#OUTPUT AREA
#ORIG LINE 
#ORIG LINE Total from Department @F0                   = @F1
	$sheet->MVPrint(44, 1,"= ");
	$sheet->MVPrint(0, 1,"Total from Department ");
	$sheet->MVPrint(46, 1,$field[1]);
	$sheet->MVPrint(22, 1,$field[0]);
#ORIG LINE 
#ORIG LINE 
#ORIG LINE 
}
#END

#SECTION: MAIN 0
#CODE AREA

#END

#SECTION: DEFAULT_MAIN 0
#CODE AREA
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
		File_name	=> "example2.out"
	);
	$report->generate();
#END
