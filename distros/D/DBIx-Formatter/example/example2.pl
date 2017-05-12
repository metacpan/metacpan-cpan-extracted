#!/usr/bin/perl
use DBIx::Formatter;

# MAIN TEST PROGRAM

format FMT_HEADER=
************************************************************
* TEST REPORT 01 --> DEPARTEMENT                           *                
************************************************************
.

format FMT_TTITLE=
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
@||||||||||||||||||||||||||||||||||||||||||||||||||||||||||+
$departement
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROG        NAME     SURNAME  AGE
----        -------- -------- --- 
.

format FMT_BODY=
@<<<        @<<<<<<< @<<<<<<< @<<
$FMT->line, $NAME,   $SURNAME $AGE
.


format FMT_DEPARTEMENT=

BREAK SUM @<<<< COUNT @<<<< AVG @<<<< 
$BTOTALAGE,$BCOUNTAGE,$BAVGAGE
TOTAL SUM @<<<< COUNT @<<<< AVG @<<<< 
$TOTALAGE,$COUNTAGE,$AVGAGE

.

format FMT_BTITLE=
------------------------------------------------------------
@</@</@<                                              P.@<<<
10,10,99,                                         $FMT->page
.

$BREAKS[0]="departement";

        $FMT=new Formatter(
        'DBI_DRIVER'           => 'Oracle',
        'DBI_DATABASE'         => 'SIPERT',
        'DBI_USERNAME'         => 'gestadm',
        'DBI_PASSWORD'         => 'fabr1z10',
        'DBD_QUERY'            => 'SELECT NAME,SURNAME,DEPARTEMENT,AGE FROM DBDTESTTABLE ORDER BY DEPARTEMENT,NAME',
        'FORMAT_PAGESIZE'      => 40,
        'FORMAT_LINESIZE'      => 50,
        'FORMAT_FORMFEED'      => "\f",
        'FORMAT_HEADER'        => *FMT_HEADER,
        'FORMAT_TTITLE'        => *FMT_TTITLE,
        'FORMAT_BTITLE'        => *FMT_BTITLE,
        'FORMAT_BTITLE_HEIGHT' => 2,
        'FORMAT_BODY'          => *FMT_BODY,
#        'EVENT_PREHEADER'      => \&PREHEADER,
#        'EVENT_POSTHEADER'     => \&POSTHEADER,
#        'EVENT_PRETTITLE'      => \&PRETTITLE,
#        'EVENT_POSTTTITLE'     => \&POSTTTITLE,
#        'EVENT_PREBODY'        => \&PREBODY,
#        'EVENT_POSTBODY'       => \&POSTBODY,
#        'EVENT_PREBTITLE'      => \&PREBTITLE,
#        'EVENT_POSTBTITLE'     => \&POSTBTITLE,
#        'EVENT_ALLBREAKS'      => \&BREAKALL,
        'BREAKS'               => \@BREAKS,
        'BREAKS_SKIP_PAGE'     =>  {
            departement => 1,
        },
        'FORMAT_BREAKS'        =>  {
            departement => *FMT_DEPARTEMENT
        },
        'EVENT_BREAKS'         =>  {
#            CD1LVSTR => \&CD1LVSTR,
#            CDCCOSTO => \&CDCCOSTO
        },
        'COMPUTE'              => {
           'SUM'   => {
                age => TOTALAGE
           },
	   'COUNT'  => {
		age => COUNTAGE
	   },
	   'AVG'    => {
		age => AVGAGE
	   }
        },
	'COMPUTE_BREAKS'       => {
	  departement  => {
	  	'SUM'	=> {
		   age => BTOTALAGE
		},
		'COUNT' => {
		   age => BCOUNTAGE
		},
		'AVG'  => {
		   age => BAVGAGE
		}
	  }
	}
    );

    $FMT->generate();

sub PREHEADER    {$FMT->ofmt("$-\:PREHEADER","|")}
sub POSTHEADER   {$FMT->ofmt("$-\:POSTHEADER","|")}
sub PRETTITLE    {$FMT->ofmt("$-\:PRETTITLE","|")}
sub POSTTTITLE   {$FMT->ofmt("$-\:POSTTTITLE","|")}
sub PREBTITLE    {$page=$FMT->page}
sub PREBODY      {}
sub POSTBODY     {$FMT->ofmt("$-\:POSTBODY","|")}
sub POSTBTITLE   {$FMT->ofmt("$-\:POSTBTITLE","|")}

sub CD1LVSTR     {}
sub CDCCOSTO     {$FMT->putformat(*FMT_CDCCOSTO)}
sub CDDIPEND     {}

# END MAIN TEST PROGRAM
