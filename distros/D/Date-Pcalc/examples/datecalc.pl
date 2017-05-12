#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2005 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

           #########################################################
           ##                                                     ##
           ##    See http://www.engelschall.com/u/sb/datecalc/    ##
           ##    for a "live" example of this CGI script.         ##
           ##                                                     ##
           #########################################################

BEGIN { eval { require bytes; }; }
use strict;

use Date::Pcalc qw(:all);

my @date = (   Today()   );
my @data = ( @date,0,0,0 );
my @diff = ( @date,@date );

&process_query_string();

unless ($data[3] == 0 and $data[4] == 0 and $data[5] == 0)
{
    eval
    {
        if ($data[5] == 0) { @data[0..2] = Add_Delta_YM( @data[0..4] ); }
        else               { @data[0..2] = Add_Delta_YMD( @data ); }
        @data[3..5] = (0,0,0);
    };
    if ($@) { @data = ( @date,0,0,0 ); }
}

&print_page();

sub process_query_string()
{
    my $query = $ENV{'QUERY_STRING'} || $ENV{'REDIRECT_QUERY_STRING'} || '';
    my @pairs = split(/&/, $query);
    my($pair,$var,$val);

    foreach $pair (@pairs)
    {
        ($var,$val) = split(/=/,$pair,2);
        if    ($var eq 'y')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <= 32767) { $data[0] = $val; }
        }
        elsif ($var eq 'm')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <=    12) { $data[1] = $val; }
        }
        elsif ($var eq 'd')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <=    31) { $data[2] = $val; }
        }
        elsif ($var eq 'dy')
        {
            if ($val =~ m!^[+-]?[0-9]+$!) { $data[3] = $val; }
        }
        elsif ($var eq 'dm')
        {
            if ($val =~ m!^[+-]?[0-9]+$!) { $data[4] = $val; }
        }
        elsif ($var eq 'dd')
        {
            if ($val =~ m!^[+-]?[0-9]+$!) { $data[5] = $val; }
        }
        elsif ($var eq 'y1')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <= 32767) { $diff[0] = $val; }
        }
        elsif ($var eq 'm1')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <=    12) { $diff[1] = $val; }
        }
        elsif ($var eq 'd1')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <=    31) { $diff[2] = $val; }
        }
        elsif ($var eq 'y2')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <= 32767) { $diff[3] = $val; }
        }
        elsif ($var eq 'm2')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <=    12) { $diff[4] = $val; }
        }
        elsif ($var eq 'd2')
        {
            if ($val =~ m!^[+-]?[0-9]+$! and $val >= 1 and $val <=    31) { $diff[5] = $val; }
        }
    }
    unless (check_date( @data[0..2] )) { @data[0..2] = @date; }
    unless (check_date( @diff[0..2] )) { @diff[0..2] = @date; }
    unless (check_date( @diff[3..5] )) { @diff[3..5] = @date; }
}

sub print_page()
{
    my($date) = Date_to_Text_Long( @data[0..2] );
    my $delta = Delta_Days(@diff);
    my $diff0 = join(', ', Enumerate(            $delta,qw(           day)) );
    my $diff1 = join(', ', Enumerate(  Delta_YMD(@diff),qw(year month day)) );
    my $diff2 = join(', ', Enumerate(N_Delta_YMD(@diff),qw(year month day)) );

    print <<"VERBATIM";
Content-type: text/html; charset="iso-8859-1"

<HTML>
<HEAD>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
    <META HTTP-EQUIV="pragma"       CONTENT="no-cache">
    <META HTTP-EQUIV="expires"      CONTENT="now">
    <TITLE>Steffen Beyer's Date Calculator</TITLE>
</HEAD>
<BODY BGCOLOR="#F0F0F0">
<CENTER>

<P>
<HR NOSHADE SIZE="2">
<P>
    <H1>Steffen Beyer's Date Calculator</H1>
<P>
<HR NOSHADE SIZE="2">
<P>

<FORM METHOD="GET" ACTION="">
<TABLE BGCOLOR="#DBDBDB" CELLSPACING="1" CELLPADDING="12" BORDER="1">
<TR>
<TD ALIGN="center" COLSPAN="6"><B>+</B></TD>
</TR>
<TR>
<TD ALIGN="center" WIDTH="100">Year</TD>
<TD ALIGN="center" WIDTH="100">Month</TD>
<TD ALIGN="center" WIDTH="100">Day</TD>
<TD ALIGN="center" WIDTH="100">Delta-Year</TD>
<TD ALIGN="center" WIDTH="100">Delta-Month</TD>
<TD ALIGN="center" WIDTH="100">Delta-Day</TD>
</TR>
<TR>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="y"  VALUE="$data[0]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="m"  VALUE="$data[1]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="d"  VALUE="$data[2]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="dy" VALUE="$data[3]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="dm" VALUE="$data[4]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="dd" VALUE="$data[5]"></TD>
</TR>
<INPUT TYPE="hidden" NAME="y1" VALUE="$diff[0]"></TD>
<INPUT TYPE="hidden" NAME="m1" VALUE="$diff[1]"></TD>
<INPUT TYPE="hidden" NAME="d1" VALUE="$diff[2]"></TD>
<INPUT TYPE="hidden" NAME="y2" VALUE="$diff[3]"></TD>
<INPUT TYPE="hidden" NAME="m2" VALUE="$diff[4]"></TD>
<INPUT TYPE="hidden" NAME="d2" VALUE="$diff[5]"></TD>
<TR>
<TD ALIGN="center" COLSPAN="6"><FONT COLOR="#FF0000">$date</FONT></TD>
</TR>
<TR>
<TD ALIGN="center" COLSPAN="3"><INPUT TYPE="reset" VALUE="CE"></TD>
<TD ALIGN="center" COLSPAN="3"><INPUT TYPE="submit" VALUE="="></TD>
</FORM>
</TR>
<TR>
<FORM METHOD="GET" ACTION="">
<INPUT TYPE="hidden" NAME="y"  VALUE="$date[0]"></TD>
<INPUT TYPE="hidden" NAME="m"  VALUE="$date[1]"></TD>
<INPUT TYPE="hidden" NAME="d"  VALUE="$date[2]"></TD>
<INPUT TYPE="hidden" NAME="dy" VALUE="0"></TD>
<INPUT TYPE="hidden" NAME="dm" VALUE="0"></TD>
<INPUT TYPE="hidden" NAME="dd" VALUE="0"></TD>
<INPUT TYPE="hidden" NAME="y1" VALUE="$date[0]"></TD>
<INPUT TYPE="hidden" NAME="m1" VALUE="$date[1]"></TD>
<INPUT TYPE="hidden" NAME="d1" VALUE="$date[2]"></TD>
<INPUT TYPE="hidden" NAME="y2" VALUE="$date[0]"></TD>
<INPUT TYPE="hidden" NAME="m2" VALUE="$date[1]"></TD>
<INPUT TYPE="hidden" NAME="d2" VALUE="$date[2]"></TD>
<TD ALIGN="center" COLSPAN="6"><INPUT TYPE="submit" VALUE="C"></TD>
</FORM>
</TR>
</TABLE>

<P>
<HR NOSHADE SIZE="2">
<P>

<FORM METHOD="GET" ACTION="">
<TABLE BGCOLOR="#DBDBDB" CELLSPACING="1" CELLPADDING="12" BORDER="1">
<TR>
<TD ALIGN="center" COLSPAN="6"><B>-</B></TD>
</TR>
<TR>
<TD ALIGN="center" WIDTH="100">Year(1)</TD>
<TD ALIGN="center" WIDTH="100">Month(1)</TD>
<TD ALIGN="center" WIDTH="100">Day(1)</TD>
<TD ALIGN="center" WIDTH="100">Year(2)</TD>
<TD ALIGN="center" WIDTH="100">Month(2)</TD>
<TD ALIGN="center" WIDTH="100">Day(2)</TD>
</TR>
<TR>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="y1" VALUE="$diff[0]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="m1" VALUE="$diff[1]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="d1" VALUE="$diff[2]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="y2" VALUE="$diff[3]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="m2" VALUE="$diff[4]"></TD>
<TD ALIGN="center"><INPUT TYPE="text" SIZE="6" MAXLENGTH="6" NAME="d2" VALUE="$diff[5]"></TD>
</TR>
<INPUT TYPE="hidden" NAME="y"  VALUE="$data[0]"></TD>
<INPUT TYPE="hidden" NAME="m"  VALUE="$data[1]"></TD>
<INPUT TYPE="hidden" NAME="d"  VALUE="$data[2]"></TD>
<INPUT TYPE="hidden" NAME="dy" VALUE="$data[3]"></TD>
<INPUT TYPE="hidden" NAME="dm" VALUE="$data[4]"></TD>
<INPUT TYPE="hidden" NAME="dd" VALUE="$data[5]"></TD>
<TR>
VERBATIM
    if (abs($delta) > 30)
    {
        print <<"VERBATIM";
<TD ALIGN="right" COLSPAN="3"><FONT COLOR="#FF0000">$diff0</FONT></TD>
<TD ALIGN="left"  COLSPAN="3">(absolute semantics)</TD>
</TR>
<TR>
VERBATIM
    }
    if ($diff1 eq $diff2)
    {
        print <<"VERBATIM";
<TD ALIGN="right" COLSPAN="3"><FONT COLOR="#FF0000">$diff1</FONT></TD>
<TD ALIGN="left"  COLSPAN="3">(both one-by-one and left-to-right semantics)</TD>
VERBATIM
    }
    else
    {
        print <<"VERBATIM";
<TD ALIGN="right" COLSPAN="3"><FONT COLOR="#FF0000">$diff1</FONT></TD>
<TD ALIGN="left"  COLSPAN="3">(one-by-one semantics)</TD>
</TR>
<TR>
<TD ALIGN="right" COLSPAN="3"><FONT COLOR="#FF0000">$diff2</FONT></TD>
<TD ALIGN="left"  COLSPAN="3">(left-to-right with truncation semantics)</TD>
VERBATIM
    }
    print <<"VERBATIM";
</TR>
<TR>
<TD ALIGN="center" COLSPAN="3"><INPUT TYPE="reset" VALUE="CE"></TD>
<TD ALIGN="center" COLSPAN="3"><INPUT TYPE="submit" VALUE="="></TD>
</FORM>
</TR>
<TR>
<FORM METHOD="GET" ACTION="">
<INPUT TYPE="hidden" NAME="y"  VALUE="$date[0]"></TD>
<INPUT TYPE="hidden" NAME="m"  VALUE="$date[1]"></TD>
<INPUT TYPE="hidden" NAME="d"  VALUE="$date[2]"></TD>
<INPUT TYPE="hidden" NAME="dy" VALUE="0"></TD>
<INPUT TYPE="hidden" NAME="dm" VALUE="0"></TD>
<INPUT TYPE="hidden" NAME="dd" VALUE="0"></TD>
<INPUT TYPE="hidden" NAME="y1" VALUE="$date[0]"></TD>
<INPUT TYPE="hidden" NAME="m1" VALUE="$date[1]"></TD>
<INPUT TYPE="hidden" NAME="d1" VALUE="$date[2]"></TD>
<INPUT TYPE="hidden" NAME="y2" VALUE="$date[0]"></TD>
<INPUT TYPE="hidden" NAME="m2" VALUE="$date[1]"></TD>
<INPUT TYPE="hidden" NAME="d2" VALUE="$date[2]"></TD>
<TD ALIGN="center" COLSPAN="6"><INPUT TYPE="submit" VALUE="C"></TD>
</FORM>
</TR>
</TABLE>

<P>
<HR NOSHADE SIZE="2">
<P>

<A HREF="http://www.engelschall.com/u/sb/download/pkg/Date-Pcalc-6.1.tar.gz">Download</A>
the Perl software that does all <A HREF="datecalc.pl">this</A>!

<P>
<HR NOSHADE SIZE="2">
<P>

</CENTER>
</BODY>
</HTML>
VERBATIM
}

sub Enumerate
{
    my(@data) = @_;
    my($i);
    my $n = scalar(@data) >> 1;
    for ( $i = 0; $i < $n; $i++ )
    {
        $data[$i] = ( ($data[$i] > 0) ? '+' : '' ) . $data[$i] . ' ' . $data[$i+$n] . ( (abs($data[$i]) == 1) ? '' : 's' );
    }
    splice(@data,$n);
    return(@data);
}

__END__

