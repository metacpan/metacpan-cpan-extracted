#!/usr/local/bin/perl
#SIZE 80 30
#OUTPUTFILE example1.out
#SOURCE Sybsource 0
#QUERY use master
#QUERY set rowcount 100
#QUERY select * from sysobjects 
#QUERY order by type
#SECTION: DEFAULT_USES 0
#CODE AREA
use strict;
use Data::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Sybsource;
#END

#SECTION: USES 0
#CODE AREA
use vars qw ($elemstype $totaltypes);
#END

#SECTION: HEADER 0
sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE --------------------------------------------------------------------------------
	$sheet->MVPrint(0, 0,"--------------------------------------------------------------------------------");
#ORIG LINE                         Example of use of Data::Reporter              @D1
	$sheet->MVPrint(24, 1,"Example of use of Data::Reporter              ");
	$sheet->MVPrint(70, 1,$report->date(1));
#ORIG LINE              Output from query: select * from sysobjects (firts 100 records)
	$sheet->MVPrint(13, 2,"Output from query: select * from sysobjects (firts 100 records)");
#ORIG LINE @T1                     Program generated with VisRep.pl               @P1
	$sheet->MVPrint(71, 3,"PAG : ".$report->page(1));
	$sheet->MVPrint(0, 3,$report->time(1));
	$sheet->MVPrint(24, 3,"Program generated with VisRep.pl               ");
#ORIG LINE --------------------------------------------------------------------------------
	$sheet->MVPrint(0, 4,"--------------------------------------------------------------------------------");
}
#END

#SECTION: TITLE 0
sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE         Name             Id        uid      type    userstat  sysstat  indexdel
	$sheet->MVPrint(8, 0,"Name             Id        uid      type    userstat  sysstat  indexdel");
#ORIG LINE -------------------- --------- --------- --------- --------- --------- ---------
	$sheet->MVPrint(0, 1,"-------------------- --------- --------- --------- --------- --------- ---------");
}
#END

#SECTION: DETAIL 0
sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0]  = substr($rep_actline->[0], 0, 20);
$field[1]  = $rep_actline->[1];
$field[2]  = $rep_actline->[2];
$field[3]  = $rep_actline->[3];
$field[4]  = $rep_actline->[4];
$field[5]  = $rep_actline->[5];
$field[6]  = $rep_actline->[6];
$elemstype++;
#OUTPUT AREA
#ORIG LINE @F0                  @F1          @F2       @F3       @F4        @F5      @F6
	$sheet->MVPrint(44, 0,$field[3]);
	$sheet->MVPrint(0, 0,$field[0]);
	$sheet->MVPrint(54, 0,$field[4]);
	$sheet->MVPrint(74, 0,$field[6]);
	$sheet->MVPrint(65, 0,$field[5]);
	$sheet->MVPrint(21, 0,$field[1]);
	$sheet->MVPrint(34, 0,$field[2]);
}
#END

#SECTION: FUNCTIONS 0
#CODE AREA
sub init_globals() {
	$elemstype  = 0;
	$totaltypes = 0;
}
#END

#SECTION: FOOTER 0
sub FOOTER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE --------------------------------------------------------------------------------
	$sheet->MVPrint(0, 0,"--------------------------------------------------------------------------------");
#ORIG LINE This is a simple footer
	$sheet->MVPrint(0, 1,"This is a simple footer");
}
#END

#SECTION: FINAL 0
sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0] = $totaltypes;
#OUTPUT AREA
#ORIG LINE 
#ORIG LINE There were @F0 number of types
	$sheet->MVPrint(0, 1,"There were ");
	$sheet->MVPrint(11, 1,$field[0]);
	$sheet->MVPrint(15, 1,"number of types");
#ORIG LINE End of Report
	$sheet->MVPrint(0, 2,"End of Report");
}
#END

#SECTION: BREAK_1 3
sub BREAK_1($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
$field[0] = $rep_actline->[3];
$field[1] = sprintf("%3d", $elemstype);
$elemstype =0;
$totaltypes++;
$report->newpage()unless $report->eOR();
#OUTPUT AREA
#ORIG LINE 
#ORIG LINE Number of elements from type @F0 : @F1
	$sheet->MVPrint(35, 1,$field[1]);
	$sheet->MVPrint(0, 1,"Number of elements from type ");
	$sheet->MVPrint(29, 1,$field[0]);
	$sheet->MVPrint(33, 1,": ");
#ORIG LINE 
#ORIG LINE 
#ORIG LINE 
}
#END

#SECTION: MAIN 0
#CODE AREA
init_globals();
#END

#SECTION: DEFAULT_MAIN 0
#CODE AREA
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
		File_name	=> "example1.out"
	);
	$report->generate();
#END
