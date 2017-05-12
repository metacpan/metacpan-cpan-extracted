###########################################################################
# PACKAGE:  Formatter
###########################################################################
# AUTH Vecchio Fabrizio (pay0vec)
# DATE 5/1/00 - 11.23
# FILE Formatter.pm
# COPY Payroll S.r.l.
###########################################################################
# NOTE Perform report generation
###########################################################################

package Formatter;

use vars qw($VERSION);
use DBI;

require Exporter;
@ISA=qw(Exporter);

$VERSION='0.01';



#######:> new
# DATE :> 5/1/00 - 11.30
# NOTE :> Costruttore oggetto Formatter
############################################################################
sub new
 {
  my $type=shift;
  my $class=ref($type) || $type;
  my %params=@_;
  my $shelf={};
  my ($key)="";

  $self->{TYPE}=$type;
  bless $self;
  $self->_DEFINE_ERRORS;

  foreach $key (keys %params) {
    $self->{PRG_CALLER}=$params{$key}               if ( $key eq "PRG_CALLER" );
    $self->{DBI_DRIVER}=$params{$key}               if ( $key eq "DBI_DRIVER" );
    $self->{DBI_DATABASE}=$params{$key}             if ( $key eq "DBI_DATABASE" );
    $self->{DBI_USERNAME}=$params{$key}             if ( $key eq "DBI_USERNAME" );
    $self->{DBI_PASSWORD}=$params{$key}             if ( $key eq "DBI_PASSWORD" );
    $self->{DBD_QUERY}=$params{$key}                if ( $key eq "DBD_QUERY");
    $self->{FORMAT_PAGESIZE}=$params{$key}          if ( $key eq "FORMAT_PAGESIZE" );
    $self->{FORMAT_LINESIZE}=$params{$key}          if ( $key eq "FORMAT_LINESIZE" );
    $self->{FORMAT_FORMFEED}=$params{$key}          if ( $key eq "FORMAT_FORMFEED" );
    $self->{FORMAT_HEADER}=$params{$key}            if ( $key eq "FORMAT_HEADER" );
    $self->{FORMAT_TTITLE}=$params{$key}            if ( $key eq "FORMAT_TTITLE" );
    $self->{FORMAT_BTITLE}=$params{$key}            if ( $key eq "FORMAT_BTITLE" );
    $self->{FORMAT_BTITLE_HEIGHT}=$params{$key}     if ( $key eq "FORMAT_BTITLE_HEIGHT" );
    $self->{FORMAT_BODY}=$params{$key}              if ( $key eq "FORMAT_BODY" );
    $self->{EVENT_PREHEADER}=$params{$key}          if ( $key eq "EVENT_PREHEADER" );
    $self->{EVENT_POSTHEADER}=$params{$key}         if ( $key eq "EVENT_POSTHEADER" );
    $self->{EVENT_PREBODY}=$params{$key}            if ( $key eq "EVENT_PREBODY" );
    $self->{EVENT_POSTBODY}=$params{$key}           if ( $key eq "EVENT_POSTBODY" );
    $self->{EVENT_PRETTITLE}=$params{$key}          if ( $key eq "EVENT_PRETTITLE" );
    $self->{EVENT_POSTTTITLE}=$params{$key}         if ( $key eq "EVENT_POSTTTITLE" );
    $self->{EVENT_PREBTITLE}=$params{$key}          if ( $key eq "EVENT_PREBTITLE" );
    $self->{EVENT_POSTBTITLE}=$params{$key}         if ( $key eq "EVENT_POSTBTITLE" );
    $self->{EVENT_ALLBREAKS}=$params{$key}          if ( $key eq "EVENT_ALLBREAKS" );
    $self->_FMT_GENBREAKS($params{$key})            if ( $key eq "EVENT_BREAKS" );
    $self->{BREAKS}=$params{$key}                   if ( $key eq "BREAKS" );
    $self->{FORMAT_BREAKS}=$params{$key}            if ( $key eq "FORMAT_BREAKS" );
    $self->{BREAKS_SKIP_PAGE}=$params{$key}         if ( $key eq "BREAKS_SKIP_PAGE" );
    $self->{COMPUTE}=$params{$key}                  if ( $key eq "COMPUTE" );
    $self->{COMPUTE_BREAKS}=$params{$key}           if ( $key eq "COMPUTE_BREAKS" );
  }
    $self->{PRG_CALLER}="main" if ! defined ($self->{PRG_CALLER});
    $self->{FORMAT_LINESIZE}=130 if ! defined ($self->{FORMAT_LINESIZE});

    $self->_HANDLE_ERRORS(4)  if ! defined ($self->{DBI_DRIVER});
    $self->_HANDLE_ERRORS(5)  if ! defined ($self->{DBI_DATABASE});
    $self->_HANDLE_ERRORS(6)  if ! defined ($self->{DBI_USERNAME});
    $self->_HANDLE_ERRORS(7)  if ! defined ($self->{DBI_PASSWORD});
    $self->_HANDLE_ERRORS(8)  if ! defined ($self->{DBD_QUERY});
    $self->_HANDLE_ERRORS(11) if ((defined $self->{FORMAT_BTITLE}) && (!defined $self->{FORMAT_BTITLE_HEIGHT}));

    bless $self;
}   ##new

#######:> _DBI_CONNECT
# DATE :> 5/1/00 - 12.13
# NOTE :>  Perform connection to database
############################################################################
sub _DBI_CONNECT
 {
    my $self=shift;
    my ($error)=1;
    my ($nodriver)=1;

    foreach (DBI->available_drivers) {
        $error=0 if ( $_ eq $self->{DBI_DRIVER} );
        $nodriver=0;
    };

    $error=2 if $nodriver;

    if ( ! $error ) {
        $self->{DBH}=DBI->connect(
            "dbi:".$self->{DBI_DRIVER}.":".$self->{DBI_DATABASE},
            $self->{DBI_USERNAME},
            $self->{DBI_PASSWORD}, {
                PrintError => 0
            }
        ) || $self->_HANDLE_ERRORS(3);
    } else {
        $self->_HANDLE_ERRORS($error);
    };
}   ##_DBI_CONNECT

#######:> _DBI_DISCONNECT
# DATE :> 5/1/00 - 13.29
# NOTE :> Perform database disconnection
############################################################################
sub _DBI_DISCONNECT
 {
    my $self=shift;
    $self->{DBH}->disconnect;
}   ##_DBI_DISCONNECT


#######:> _DBI_FETCHROW_HASHREF
# DATE :> 5/1/00 - 13.50
# NOTE :> Perform DBI fetchrow_hashref
############################################################################
sub _DBI_FETCHROW_HASHREF
 {
    my $self=shift;
    my $h_rows={};
    my $firstloop=1;
    my $v_name="";
    my $cmd="";


    $self->_DBI_CONNECT;
    $self->{STH}=$self->{DBH}->prepare($self->{DBD_QUERY}) || $self->_HANDLE_ERRORS(9,$self->{DBH}->errstr);
    $self->{STH}->execute || $self->_HANDLE_ERRORS(9,$self->{DBH}->errstr);


    format TMPTOP=
.
    $^=TMPTOP;
    $==$self->{FORMAT_PAGESIZE};
    $^L=$self->{FORMAT_FORMFEED};
    $-=$=;
    $%=1;

    while ( $h_rows=$self->{STH}->fetchrow_hashref ) {

        # Genearation of caller program variable
        $self->{NEWPAGE}=0;

        foreach $key ( keys %$h_rows ) {
            $v_name=$self->{PRG_CALLER}."::".uc($key);
            $$v_name=$h_rows->{$key};
            $self->{ROWS}->{$key}=$h_rows->{$key};
            $self->{LAST_BREAKS}->{$key}=$h_rows->{$key} if $firstloop;
        };
        bless $self;


        if ( $firstloop ) {
            $self->header;
            $firstloop=0;
        }

        $self->breaks(1) if ! $firstloop;
	$self->compute;
	$self->compute_breaks;
        $self->breaks_events;


        $self->newpage if ( $-== $self->{FORMAT_BTITLE_HEIGHT} );
        $self->body;
    };

    $self->{LAST_BREAKS}={}; bless $self;
    $self->breaks(0);
    $self->bottomtitle;

    $self->{STH}->finish || $self->_HANDLE_ERRORS(9,$self->{DBH}->errstr);
    $self->_DBI_DISCONNECT;

}   ##_DBI_FETCHROW_HASHREF

#######:> compute_breaks
# DATE :> 7/1/00 - 18.30
# NOTE :> Check the for compute in breaks
############################################################################
sub compute_breaks {
   my $self=shift;
   my $break=$self->{COMPUTE_BREAKS};

   foreach $key (keys %$break) {
	$compute=$break->{$key};
    	foreach $operation (keys %$compute) {
        	$fields=$compute->{$operation};
		foreach $field (keys %$fields) {
        		$self->sum   ($field,$fields->{$field}) if ( uc($operation) eq "SUM"   );
        		$self->count ($field,$fields->{$field}) if ( uc($operation) eq "COUNT" );
        		$self->avg   ($field,$fields->{$field}) if ( uc($operation) eq "AVG" );
		};
    	};
   };

};



#######:> compute
# DATE :> 7/1/00 - 18.30
# NOTE :> Check the for compute in global
############################################################################
sub compute
 {
    my $self=shift;
    my $compute=$self->{COMPUTE};

    foreach $operation (keys %$compute) {
        $fields=$compute->{$operation};
	foreach $field (keys %$fields) {
        	$self->sum   ($field,$fields->{$field}) if ( uc($operation) eq "SUM"   );
        	$self->count ($field,$fields->{$field}) if ( uc($operation) eq "COUNT" );
        	$self->avg   ($field,$fields->{$field}) if ( uc($operation) eq "AVG" );
	};
    };

}   ##compute

#######:> sum
# DATE :> 7/1/00 - 18.38
# NOTE :> Perform sum of field
############################################################################
sub sum
 {
    my $self=shift;
    my $field=@_[0];
    my $total=@_[1];

    $self->{CSUM}->{$total}+=$self->{ROWS}->{$field};
    $v_name=$self->{PRG_CALLER}."::".$total;
    $$v_name=$self->{CSUM}->{$total};

    bless $self;
    return $self->{CSUM}->{$total};
}   ##sum

#######:> count
# DATE :> 7/1/00 - 18.38
# NOTE :> Perform count of field
############################################################################
sub count
 {
    my $self=shift;
    my $field=@_[0];
    my $total=@_[1];

    $self->{CCOUNT}->{$total}++;
    $v_name=$self->{PRG_CALLER}."::".$total;
    $$v_name=$self->{CCOUNT}->{$total};

    bless $self;
    return $self->{CCOUNT}->{$total};
}   ##count

#######:> avg
# DATE :> 7/1/00 - 18.38
# NOTE :> Perform averange of field
############################################################################
sub avg
 {
    my $self=shift;
    my $field=@_[0];
    my $total=@_[1];

    $self->{CAVG}->{$total}=$self->sum($field,"CAVG".$total) / $self->count($field,"CAVG".$total);
    $v_name=$self->{PRG_CALLER}."::".$total;
    $$v_name=$self->{CAVG}->{$total};

    bless $self;
    return $self->{CAVG}->{$total};
}   ##avg

#######:> breaks_events
# DATE :> 7/1/00 - 15.31
# NOTE :> Perform check for breaks events
############################################################################
sub breaks_events
 {
    my $self=shift;
    my $breaks_event=$self->{EVENT_BREAKS};
    my $breaks=$self->{BREAKS};
    my $brk_routine="";

    foreach $key (@$breaks) {
        $brk_routine=$breaks_event->{$key};
        &$brk_routine if (($self->{LAST_BREAKS_EVENTS}->{$key} ne $self->{ROWS}->{$key}) && (defined $self->{EVENT_BREAKS}->{$key}));
        $self->{LAST_BREAKS_EVENTS}->{$key}=$self->{ROWS}->{$key};
    };

    bless $self;
}   ##breaks

#######:> breaks
# DATE :> 7/1/00 - 15.31
# NOTE :> Perform check for breaks
############################################################################
sub breaks
 {
    my $self=shift;
    my $skippage=@_[0];
    my $breaks_event=$self->{EVENT_BREAKS};
    my $breaks=$self->{BREAKS};
    my $brk_routine="";
    my $newpage=0;

    foreach $key (@$breaks) {
        $brk_routine=$breaks_event->{$key};
        if (($self->{LAST_BREAKS}->{$key} ne $self->{ROWS}->{$key})) {
            $self->fmt_breaks($key) if defined $self->{FORMAT_BREAKS}->{$key};
            $newpage=1 if $self->{BREAKS_SKIP_PAGE}->{$key};

    	    $coumpute=$self->{COMPUTE_BREAKS}->{$key};
            foreach $operation (keys %$compute) {
		$fields=$compute->{$operation};
		foreach $field (keys %$fields) {
			$self->{CSUM}->{$fields->{$field}}=0          if (uc($operation) eq "SUM");
			$self->{CCOUNT}->{$fields->{$field}}=0        if (uc($operation) eq "COUNT");
			$self->{CAVG}->{$fields->{$field}}=0          if (uc($operation) eq "AVG");
			$self->{CSUM}->{"CAVG".$fields->{$field}}=0   if (uc($operation) eq "AVG");
			$self->{CCOUNT}->{"CAVG".$fields->{$field}}=0 if (uc($operation) eq "AVG");
		};
	    };

        }
        $self->{LAST_BREAKS}->{$key}=$self->{ROWS}->{$key};
    };

    $self->newpage if ($newpage && $skippage);
    bless $self;
}   ##breaks


#######:> header
# DATE :> 7/1/00 - 09.37
# NOTE :> Print out the header for the report
############################################################################
sub header
 {
    $self=shift;

    if ( defined $self->{FORMAT_HEADER} ) {
        $~="$self->{FORMAT_HEADER}";
        $self->_HANDLE_EVENTS("EVENT_PREHEADER");
        write;
        $self->_HANDLE_EVENTS("EVENT_POSTHEADER");
    }

    $self->formfeed;
    $-=0;
    $self->toptitle;
}   ##header


#######:> body
# DATE :> 7/1/00 - 09.23
# NOTE :> Print out the body of the page
############################################################################
sub body {
    my $self=shift;
    my $savefmt="";

    $savefmt=$~;

    if ( defined $self->{FORMAT_BODY} ) {
        $~="$self->{FORMAT_BODY}";
        $self->_HANDLE_EVENTS("EVENT_PREBODY");
        write;
        $self->_HANDLE_EVENTS("EVENT_POSTBODY");
    };

   $~=$savefmt;
}   ##body

#######:> fmt_breaks
# DATE :> 7/1/00 - 16.43
# NOTE :> Perform write format for breaks
############################################################################
sub fmt_breaks
 {
    my $self=shift;
    my $break_key=@_[0];
    my $savefmt="";

    $savefmt=$~;

    if ( defined $self->{FORMAT_BREAKS}->{$key} ) {
        $~="$self->{FORMAT_BREAKS}->{$break_key}";
        write;
    };

   $~=$savefmt;
}   ##fmt_breaks


#######:> bottomtitle
# DATE :> 7/1/00 - 09.21
# NOTE :> Print out the bottom title for the page
############################################################################
sub bottomtitle
 {
    my $self=shift;
    my $savefmt="";

    $savefmt=$~;
    if ( defined $self->{FORMAT_BTITLE} ) {
        $~="$self->{FORMAT_BTITLE}";
        $self->_HANDLE_EVENTS("EVENT_PREBTITLE");
        write;
        $self->_HANDLE_EVENTS("EVENT_POSTBTITLE");
    };

    $~=$savefmt;

}   ##bottomtitile


#######:> toptitle
# DATE :> 7/1/00 - 09.16
# NOTE :> Print out the top title for the page
############################################################################
sub toptitle
 {
    my $self=shift;
    my $savefmt="";

    $savefmt=$~;

    if ( defined $self->{FORMAT_TTITLE} ) {
        $-=$=;
        $~="$self->{FORMAT_TTITLE}";
        $self->_HANDLE_EVENTS("EVENT_PRETTITLE");
        write;
        $self->_HANDLE_EVENTS("EVENT_POSTTTITLE");
    };

    $~=$savefmt;
}   ##toptitle


#######:> generate
# DATE :> 5/1/00 - 17.26
# NOTE :> Perform generation of reprot
############################################################################
sub generate
 {
    my $self=shift;

    $self->_DBI_FETCHROW_HASHREF;
}   ##generate

#######:> putformat
# DATE :> 7/1/00 - 17.31
# NOTE :> Put a format in the report
############################################################################
sub putformat
 {
    $self=shift;
    $tmp_format=@_[0];
    my $savefmt="";

    $savefmt=$~;
    $~="$tmp_format";
    write;
    $~=$savefmt;
}   ##putformat

#######:> newpage
# DATE :> 5/1/00 - 17.06
# NOTE :> Send a new page event
############################################################################
sub newpage
 {
    my $self=shift;

    $self->{NEWPAGE}=1;
    $self->bottomtitle;
    $self->formfeed;
    $self->toptitle;
    bless $self;

}   ##newpage

#######:> isnewpage
# DATE :> 7/1/00 - 16.25
# NOTE :> Query if a new page is been performed
############################################################################
sub isnewpage
 {
    $self=shift;
    return $self->{NEWPAGE};
}   ##isnewpage

#######:> formfeed
# DATE :> 7/1/00 - 09.15
# NOTE :> Send a formfeed to the report
############################################################################
sub formfeed
 {
    my $self=shift;
    printf $^L;
    $%++;
    $-=$=;

}   ##formfeed

#######:> page
# DATE :> 7/1/00 - 10.31
# NOTE :> Get the page number
############################################################################
sub page
 {
    $self=shift;
    return $%;
}   ##page

#######:> line
# DATE :> 7/1/00 - 10.38
# NOTE :> Get the line number for current page
############################################################################
sub line
 {
    $self=shift;
    return ($=-$-+1);
}   ##line


#######:> ofmt
# DATE :> 5/1/00 - 17.17
# NOTE :> Perform a printf statement and decrease $- value
############################################################################
sub ofmt
 {
    my $self=shift;
    my ($s_value,$params,$position)=@_;
    my ($t_value)="";

    ($t_value=$s_value)=~ s/\n//g;
    $params="<" if ! defined $params;
    $position-- if defined $position;
    $position=0 if ((! defined $position) || ($position > $self->{FORMAT_LINESIZE}) || ($position < 0));

    $self->_HANDLE_ERRORS(10) if (($params ne "<") && ($params ne ">") && ($params ne "|") && ($params ne "@"));

    printf "%".$self->{FORMAT_LINESIZE}."s\n",substr($s_value,0,$self->{FORMAT_LINESIZE}) if $params eq ">";
    printf "%-".$self->{FORMAT_LINESIZE}."s\n",substr($s_value,0,$self->{FORMAT_LINESIZE}) if $params eq "<";
    printf "%-".$self->{FORMAT_LINESIZE}."s\n",(" " x (int(($self->{FORMAT_LINESIZE} /2) - (length(substr($s_value,0,$self->{FORMAT_LINESIZE}))/2)))).substr($s_value,0,$self->{FORMAT_LINESIZE}) if $params eq "|";
    printf "%-".$self->{FORMAT_LINESIZE}."s\n",(" " x ($position)).substr($s_value,0,$self->{FORMAT_LINESIZE}-$position) if $params eq "@";
    $---;
    $self->formfeed if ( $-==0);
}   ##ofmt

#######:> _HANDLE_EVENTS
# DATE :> 7/1/00 - 09.43
# NOTE :> Perform event generation
############################################################################
sub _HANDLE_EVENTS
 {
    my $self=shift;
    my $EVENT=@_[0];
    my $EVENT_ROUTINE="";

    if ( defined $self->{$EVENT} ) {
        $EVENT_ROUTINE=$self->{$EVENT};
        &$EVENT_ROUTINE;
    }
}   ##_HANDLE_EVENTS


#######:> _HANDLE_ERRORS
# DATE :> 5/1/00 - 12.16
# NOTE :> Perform error handling in all package
############################################################################
sub _HANDLE_ERRORS
 {
    my $self=shift;
    my ($error_code,$error_msg)=@_;
    my (@desc)=();

    format ERRORFMT =
    *************************************************************************
    *                   !!! WARINING ERROR !!!                              *
    *************************************************************************
    * TYPE   : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[1]
    * NUMBER : @<<<                                                         *
               $error_code
    *************************************************************************
    * EVENT  : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[2]
    *          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[3]
    *          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[4]
    *          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[5]
    *          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[6]
    *          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[7]
    *          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
               $desc[8]
    *************************************************************************
.
    if ( defined $error_msg ) {
        my $m_start=0;
        my $m_many=length($error_msg);
        my $m_mesg="";
        while ( $m_many > 0 ) {$m_mesg=$m_mesg."|".substr($error_msg,$m_start,55);$m_many=$m_many-55;$m_start=$m_start+55}
        $self->{ERRORS}[$error_code]=$self->{ERRORS}[$error_code].$m_mesg;
    };

    @desc=split(/\|/,$self->{ERRORS}[$error_code]);
    $~=ERRORFMT; write;
    die  if ($desc[0] eq "D");
    warn if ($desc[0] eq "W");
}   ##_HANDLE_ERRORS

#######:> _FMT_GENBREAKS
# DATE :> 5/1/00 - 15.03
# NOTE :> Perform generation of hash reference for breaks
############################################################################
sub _FMT_GENBREAKS ($%)
 {
    my $self=shift;
    my $breaks=shift;

    foreach $key ( keys %$breaks ) {$self->{EVENT_BREAKS}->{$key}=$breaks->{$key}};
}   ##_FMT_GENBREAKS

#######:> _DEFINE_ERRORS
# DATE :> 5/1/00 - 12.24
# NOTE :> Load error string
############################################################################
sub _DEFINE_ERRORS
 {
    my $self=shift;

    $self->{ERRORS}[1]="D|CRITICAL|Specified DBI Driver don't exist or not installed|properly\.";
    $self->{ERRORS}[2]="D|CRITICAL|Is not possible to retrieve driver information.|Check your DBI,DBD installation\.";
    $self->{ERRORS}[3]="D|CRITICAL|Specified connection parameter possible invalid\.|Impossible connect to database\.";
    $self->{ERRORS}[4]="D|CRITICAL|Specify a DBI driver\.";
    $self->{ERRORS}[5]="D|CRITICAL|Specify a DBD database name\.";
    $self->{ERRORS}[6]="D|CRITICAL|Missing DBI username\.";
    $self->{ERRORS}[7]="D|CRITICAL|Missing DBI password\.";
    $self->{ERRORS}[8]="D|CRITICAL|Specify a query to retrieve data from database\.";
    $self->{ERRORS}[9]="D|CRITICAL";
    $self->{ERRORS}[10]="D|CRITICAL|Invalide parameter in ofmt routine\.";
    $self->{ERRORS}[11]="D|CRITICAL|FORMAT_BTITLE_HEIGHT not specified when FORMAT_BTITLE|declared\.";
}   ##_DEFINE_ERRORS

1;

=head1 NAME

Formatter - Module to perform report generation via query DBI

=head1 SYNOPSIS

    use Formatter;

    format FMT_HEADER=
    **************************************************
    *             FIRST PAGE OF REPORT               *
    **************************************************
.

    format FMT_TTITLE=
    **************************************************
    * SOC : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
            $DEAZIEND
    **************************************************
    PROG    CDAZIEND CDDIPEND
    ----    -------- --------
.

    format FMT_BODY=
    @<<<    @<<<     @<<<<<
    $FMT->line,     $CDAZIEND,$CDDIPEND
.

    format FMT_CD1LVSTR=
    TOT]--> @<<<<<<< @<<<<<<< @<<<<<<<
       111,     111,     111
.
    format FMT_BTITLE=
    --------------------------------------------------
    @</@</@<                                    P.@<<<
    $DAY,$MONTH,$YEAR,                      $FMT->page
.

        $BREAKS[0]="CDAZIEND";
        $BREAKS[1]="CDDIPEND";

        $FMT=new Formatter(
        'DBI_DRIVER'           => 'Oracle',
        'DBI_DATABASE'         => 'database',
        'DBI_USERNAME'         => 'dbusername',
        'DBI_PASSWORD'         => 'dbpassword',
        'DBD_QUERY'            => 'SELECT * FROM ANAGRA WHERE CLPERRIF=199901 ORDER BY CDAZIEND',
        'BREAKS'               => \@BREAKS,
        'BREAKS_SKIP_PAGE'     =>  {
            CD1LVSTR => 1,
            CDCCOSTO => 0
        },
        'FORMAT_PAGESIZE'      => 40,
        'FORMAT_LINESIZE'      => 50,
        'FORMAT_FORMFEED'      => "\f",
        'FORMAT_HEADER'        => *FMT_HEADER,
        'FORMAT_TTITLE'        => *FMT_TTITLE,
        'FORMAT_BTITLE'        => *FMT_BTITLE,
        'FORMAT_BTITLE_HEIGHT' => 2,
        'FORMAT_BODY'          => *FMT_BODY,
        'FORMAT_BREAKS'        =>  {
            CD1LVSTR => *FMT_CD1LVSTR,
        },
        'EVENT_PREHEADER'      => \&PREHEADER,
        'EVENT_POSTHEADER'     => \&POSTHEADER,
        'EVENT_PRETTITLE'      => \&PRETTITLE,
        'EVENT_POSTTTITLE'     => \&POSTTTITLE,
        'EVENT_PREBODY'        => \&PREBODY,
        'EVENT_POSTBODY'       => \&POSTBODY,
        'EVENT_PREBTITLE'      => \&PREBTITLE,
        'EVENT_POSTBTITLE'     => \&POSTBTITLE,
        'EVENT_ALLBREAKS'      => \&BREAKALL,
        'EVENT_BREAKS'         =>  {
            CDAZIEND => \&CDAZIEND,
            CDDIPEND => \&CDDIPEND
        }
    );

    $FMT->generate();

    sub PREHEADER    {do something before header print out}
    sub POSTHEADER   {do something after header print out}
    sub PRETTITLE    {do something before top title print out}
    sub POSTTTITLE   {do something after top title print out}
    sub PREBTITLE    {do something before bottom title print out}
    sub POSTBTITLE   {do something after bottom title print out}
    sub PREBODY      {do something before body print out}
    sub POSTBODY     {do something after body print out}

    $FMT->ofmt("Print out a line during report generation",">");

=head1 DESCRIPTION

    Formatter module perform report generation based on DBI query.


=head1 DEFINITION

=head2 Function new

The <new> function create the Formatter object and configure it
for all parameters required for report generation.
One by one parameter definition:

    * DBI_DRIVER        => Specify wath driver you would use
                           for connect to your database.
                           (See DBD drivers for specific)
    * DBI_DATABASE      => Specify database name (or instance).
                           In union of last parameter it create
                           connection string : dbi:DBI_DRIVER:DBI_DATABASE
    * DBI_USERNAME      => Specify database username
    * DBI_PASSWORD      => Specify database DBI_USERNAME password
    * DBD_QUERY         => Point to a string where Sql Query are located
    * BREAKS            => Point to an array containing fields that cause a
                           break in the report
    * BREAKS_SKIP_PAGE  => Point to an hash that specify if a new page are
                           performed when the break FORMAT ar printed
    * FORMAT_PAGESIZE   => Specify page height in character
    * FORMAT_LINESIZE   => Specify line width in character (only for outf use)
    * FORMAT_FORMFEED   => Specify formfeed sequence when a formfeed or newpage
                           are requested
    * FORMAT_HEADER     => Point to filehandle of the header definition for the
                           report
    * FORMAT_TTITLE     => Point to filehandle of the top title definition for
                           the report
    * FORMAT_BODY       => Point to filehandle of the body definition for the
                           report
    * FORMAT_BTITLE     => Point to filehandle of the bottom title definition for
                           the report
    * FORMAT_BTITLE_HEIGHT => Height in lines of BTITLE
    * FORMAT_BREAKS     => Point to an hash containig break fields related to its
                           format filehandle definition
    * EVENT_PREHEDER    => Point to the subroutine that is called before header
                           generation
    * EVENT_POSTHEDER   => Point to the subroutine that is called after header
                           generation
    * EVENT_PRETTITLE   => Point to the subroutine that is called before top title
                           generation
    * EVENT_POSTTTITLE  => Point to the subroutine that is called after top title
                           generation
    * EVENT_PREBODY     => Point to the subroutine that is called before body
                           generation
    * EVENT_POSTBODY    => Point to the subroutine that is called after body
                           generation
    * EVENT_PREBTITLE   => Point to the subroutine that is called before bottom title
                           generation
    * EVENT_POSTBTITLE  => Point to the subroutine that is called after bottom title
                           generation
    * EVENT_BREAKS      => Point to structure that contains break fields related to
                           subroutine to execute when the break is berformed

=head2 DBI_DRIVER

DBI_DRIVER specify driver to use for connection within Database via DBI::DBD module.

Ex.

    * Oracle  (Oracle database)
    * CSV     (Comma separated database)
    * Pg      (PostgreSQL database)
    ... ecc.

For specific look at DBD::<Driver>

=head2 DBI_DATABASE

The clause DBI_DATABASE can change from db to db , look at DBD::Driver for your specific.
Example parameter are:

    * ORACLE_SID            for Oracle database
    * f_dir=/csv/data       for CSV file specify directory location of text-file-table
    * dbname=your db name   for PostgreSQL database
    * DSN                   for ADO db connection


=head2 DBI_USERNAME DBI_PASSWORD

Specify in order username and password of the user granted to use database

=head2 DBD_QUERY

Here you can pass your query (SQL) , that is fetched for report generation.
Example to pass query are:

    * Example 1 (Direct via parameters)
            $FMT=new Formatter(
            'DBI_DRIVER'           => 'Oracle',
            'DBI_DATABASE'         => 'database',
            'DBI_USERNAME'         => 'dbusername',
            'DBI_PASSWORD'         => 'dbpassword',
            'DBD_QUERY'            => 'SELECT * FROM ANAGRA WHERE CLPERRIF=199901 ORDER BY CDAZIEND',
             ...

    * Example 2 (Via variable)
            $query = qq {
                SELECT
                    *
                FROM
                    ANAGRA
                WHERE
                        CLPERRIF=199901
                    AND
                        CDAZIEND=345
                ORDER BY
                    CDAZIEND
            };

            $FMT=new Formatter(
            'DBI_DRIVER'           => 'Oracle',
            'DBI_DATABASE'         => 'database',
            'DBI_USERNAME'         => 'dbusername',
            'DBI_PASSWORD'         => 'dbpassword',
            'DBD_QUERY'            => $query,
            ...

=head2 BREAKS

Specify an array containing fields that cause a break in the report.
When a breaks is performed 2 step are executed, first an EVENT_BREAKS is called if
defined , second a FORMAT_BREAKS is printed out if defined.
For convenience if you would like to generate a new format when a field change you can
use first statement because is called after FORMAT_BREAKS (and if they are subtotal are
printed before), using the putformat function in the event routine, for example:

    format FMT_DEPARTEMENT=
    TOTALS FOR DEPARTEMENT ARE ]--> @<<<<<<< @<<<<<<< @<<<<<<<
                                    111,     111,     111
.

   format FMT_SUBDEPARTEMENT
   *********************************
   * @|||||||||||||||||||||||||||| *
     $SUBDEPARTEMENT
   *********************************
.

        $BREAKS[0]="DEPARTEMENT";
        $BREAKS[1]="SUBDEPARTEMENT";

        $FMT=Formatter->new (
                ...
                'BREAKS'               => \@BREAKS,
                'BREAKS_SKIP_PAGE'     =>  {
                DEPARTEMENT => 1,
                SUBDEPARTEMENT => 0
                },
                'FORMAT_BREAKS'        =>  {
                DEPARTEMENT => *FMT_DEPARTEMENT
                },
                'EVENT_BREAKS'         =>  {
                SUBDEPARTEMENT => \&MySubDepartement
                },
                ...
        );

sub MySubDepartement {$FMT->putformat(*FMT_SUBDEPARTEMENT)};

In this way a possible output is :
*******************************************************
*                REPORT BY SUBDEPARTMENT              *
*******************************************************
   *********************************
   *           CHEMICALS           *
   *********************************
   10    20    40
   10    20    40
   10    20    40
   *********************************
   *           PHARMACIA           *
   *********************************
   10    20    40
   10    20    40
   10    20    40

TOTALS FOR DEPARTEMENT ARE ]--> 111 111 111

=head2 BREAKS_SKIP_PAGE

This parameter specify only if a new page is called after a break FORMAT is writed.

=head2 FORMAT_PAGESIZE

(Optional-Deafult=60)

Specify how many lines are printed for each piece of paper.

=head2 FORMAT_LINESIZE

(Optional-Default=130)

Specify how many character are counted by an outf function to perform
alignement of text.

=head2 FORMAT_FORMFEED

(Optional-Deafult=\f)

Specify the form feed sequence that are called whem a newpage or a formfeed
function are called ( and alse a new page of report is required)
Default value are CTRL-L (\f)

=head2 FORMAT_HEADER

(Optional)

This parameter point to the format fileheader for HEADER page.
Definition of format specific can be found in Perl documentation.
Header page is printed only one time at beginning of the report and normally
include general specification or purpose of report.

Example:

    format MY_HEADER=
    ******************************************
    * DATE    : @</@</@<<<                   *
                $dd,$mm,$yyyy
    * PURPOSE : Statistique about user login *
    ******************************************
.

=head2 FORMAT_TTITLE

(Optional)

Identical to HEADER definition.
TTITLE is printed on every change of page in the top of the report page

=head2 FORMAT_BODY

(Optional)

Identical to HEADER definition.
BODY is printed on every change of value in fetch of query statament,
values of query are passed and traslated to real variable in the main caller
program.

Example :
    if query is SELECT NAME,SURNAME,ADDRESS FROM ADDRESSBOOK
    in yours format values $NAME,$SURNAME,$ADDRESS are created and updated
    on every fetch.

    format MYBODY=
    @<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $NAME,             $SURNAME            $ADDRESS
.

=head2 FORMAT_BTITLE

(Optional)

Identical to HEADER definition.
BTITLE is printed on every change of page in the bottom of the report page

=head2 FORMAT_BTITLE_HEIGHT

(Option if FORMAT_BTITLE not specified)

This parameter specify how many lines are printed by the FORMAT_BTITLE definition.
I have put this parameter beacuse i don't know how to inform automatically my package in
what lines is used by a format definition.
If anyone know how to make it possible please contact me.

=head2 FORMAT_BREAKS

This parameter point to a structure where are located by fields format filehandle definitions.
For use see the BREAKS specifics.

=head2 EVENT_PRE...

All EVENT_PRE... (EVENT_PREHEADER,EVENT_PRETTITLE ...) parameters points to a routine defined
by the user that is called before the event handle is performed.
For example if you would like to change a value in the top title before is print out you need to
create a sub for example named MyBeforeTopTitle in which you change a value , and then you pass
this reference to the EVENT_PRETTITLE parameter :

        'EVENT_PRETTITLE' => \&MyBeforeTopTitle

Remember that all values created by the fetch statement are already updated when all events are
generated

=head2 EVENT_POST...

Is identical to the last but is applied after the event handle occurs.

=head2 EVENT_BREAKS

This parameter point to a structure that specify by fields events that can be
generated when a break is performed after a FORMAT_BREAKS is printed out.

=head1 FUNCTIONS

=head2 Function generate

This function call all parameters and build the report.

=head2 Function ofmt

This function place a text in the report over formatting definition , is only for special
case in which is impossible to place text on format definition (if you found when please
contact me).
            Formatter->ofmt ("Text to print out",position flag,position character);
* Position flag
The position flag specify where text are printed , possible values are:
    <   Text are aligned to left of the line
    >   Text are aligned to right of the line
    |   Text are aligned in the middle of the line
    C   Enable Position

* Position character
The position character specify the position in the line where the text are printed

=head2 Function page

The page function return number of page in this moment

=head2 Function line

The line function return the line position in the moment

=head2 Function newpage

The new page function send a complete new page to the report this is the next
sequence :

    * Print the bottom title in the current page
    * Send the form feed sequence
    * Print the top title in the new page

=head2 Function formfeed

The formfeed function send only the form feed sequence to the report and not
perform the title generation.

=head1 AUTHOR

              Vecchio Fabrizio <jacote@tiscalinet.it>

=head1 SEE ALSO

L<DBI>

=cut













