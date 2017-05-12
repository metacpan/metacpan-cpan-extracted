package CGI::AppBuilder::Table;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;

our $VERSION = 1.001;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(html_table html_tag table_column
                   );
our %EXPORT_TAGS = (
    table => [qw(html_table html_tag table_column)],
    all  => [@EXPORT_OK]
);

use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:all);

=head1 NAME

CGI::AppBuilder::Table - Configuration initializer 

=head1 SYNOPSIS

  use CGI::AppBuilder::Table;

  my $ab = CGI::AppBuilder::Table->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my ($q, $ar, $ar_log) = $ab->start_app($0, \%ARGV);
  print $ab->disp_form($q, $ar); 

=head1 DESCRIPTION

This class provides methods for reading and parsing configuration
files. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head2 html_table($arf, $cns, $br)

Input variables:

  $arf - array ref containing the content of the table
  $cns - column names separated by comma or
         AUTO|AH|HASH - use $k in AH Array ${$arf}[$i]{$k}
  $br  - hash array ref for table format, it contains
    css_table - CSS class name for <TABLE>
    atr_table - attribute parameters for <TABLE>
    css_tr    - CSS class name for <TR>
    atr_tr    - attribute parameters for <TR>
    atr_tr_odd  - attribute parameters for ODD <TR>
    atr_tr_even - attribute parameters for EVEN <TR>
    css_tr_odd  - CSS class name for ODD <TR>
    css_tr_even - CSS class name for EVEN <TR>
    css_select  - CSS class name for <SELECT ...>
    css_input   - CSS class name for <INPUT type=input ...>
    atr_sel   - attributes for itemized <SELECT ...> for instance:
        atr_sel = {
            var1 => 'style="display:none"',
            var2 => 'style="display:block"',
            var3 => 'class="FormSel"',
        }
    atr_inp   - attributes for itemized <INPUT type=input ...>
    css_td    - CSS class name for <TD>
    atr_td    - attribute parameters for <TD>
    atr_cell  - an array ref to attribute parameters for each cell
                ${$br}{atr_cell}[$i][$j]
    esc_vars  - a list of escaped variables separated by comma.
    fh_out    - output file handler
    cns_desc  - hash ref containing column name description
    tab_caption - table caption/header
    tab_footer  - table footer/notes
    cel_title - a hash ref storing title attribute for defined cells.
                You can define cells by the value stored in the cell
                or 'row:col'. 

Variables used or methods called:

  CGI::AppBuilder::Message
    set_param - get parameter from a hash

How to use:


  my @a = (['ColA','ColB'],[1,2],[5,6],[7,8]);
  my $txt = $self->html_table(\@a);
  my @b = ({A=>1,B=>2},{A=>5,B=>6},{A=>7,B=>8});
  my $txt = $self->html_table(\@b,"",'A,B');
  my $txt = $self->html_table(\@b,"",'A,B');

Return: generates HTML Table codes.

This method convert all the < and > into &lt; and &gt; for displaying,
except variables are specified in I<esc_vars>.

=cut

sub html_table {
    my $s = shift;
    my($ar,$cns,$br) = @_;
    return "<b>No Input for html_table!</b>\n" if !$ar;
    return "<b>Not a Array for html_table</b>\n"  if $ar !~ /ARRAY/;
    my ($cn_lst, $cr) = ("",[]);

    if (${$ar}[0] =~ /HASH/) {
        if (!$cns || $cns  =~ /^(auto|hash|AH)$/i) {
            map { $cn_lst .= "$_," } (keys %{$ar->[0]}); 
            $cn_lst =~ s/,$//; $cn_lst = lc $cn_lst;
        } else { $cn_lst = $cns; }
        $cn_lst =~ s/\s+//g;
        $cr = $ar;
    } else {    # it is an array
        if (!$cns || $cns  =~ /^(auto|hash|AH)$/i) {
            map { $cn_lst .= "$ar->[0][$_]," } 0..$#{$ar->[0]};
            $cn_lst =~ s/,$//; $cn_lst = lc $cn_lst; 
        } else { $cn_lst = $cns; }
        # $cn_lst =~ s/\s+//g;
        $cn_lst =~ s/\s+/_/g;
        my @a = split /,/, $cn_lst;
        shift @$ar;   # remove the first row
        $cr = [map{my %tmp;@tmp{@a}=@$_;\%tmp}@$ar];
    }
    return "<b>No column names are provided or defined.</b>\n" 
       if !$cn_lst;
    my $css_table = $s->set_param('css_table', $br);
    my $atr_table = $s->set_param('atr_table', $br);
    my $css_tr    = $s->set_param('css_tr', $br);
    my $atr_tr    = $s->set_param('atr_tr', $br);
    my $atr_tr_od = $s->set_param('atr_tr_odd', $br);
    my $atr_tr_ev = $s->set_param('atr_tr_even', $br);
    my $css_tr_od = $s->set_param('css_tr_odd', $br);
    my $css_tr_ev = $s->set_param('css_tr_even', $br);
    my $ar_sel    = eval $s->set_param('atr_sel', $br);
    my $ar_inp    = eval $s->set_param('atr_inp', $br);
    my $css_select= $s->set_param('css_select', $br);
    my $css_input = $s->set_param('css_input', $br);
    my $css_td    = $s->set_param('css_td', $br);
    my $atr_td    = $s->set_param('atr_td', $br);
    my $cel_title = $s->set_param('cel_title', $br);     # Cell title
    my $atr_cell  = $s->set_param('atr_cell', $br);
       $atr_cell  = eval $atr_cell    if $atr_cell;
       $atr_cell  = []                if ! $atr_cell;
    my $pretty    = $s->set_param('tab_pretty', $br);
    my $cap       = $s->set_param('tab_caption', $br);
    my $ftr       = $s->set_param('tab_footer', $br);
    my $esc_vars  = $s->set_param('esc_vars', $br);
    my $esc = ($esc_vars) ? {  
        map { $_ => 1 } (split /,/,$esc_vars) 
        } : {};
    # my $tr = $s->html_tag('TR',
    #     {class=>$css_tr,attr=>$atr_tr,pretty=>$pretty});
    my $t  = $s->html_tag('TABLE',
        {class=>$css_table,attr=>$atr_table,pretty=>$pretty});
       $t .= $s->html_tag('CAPTION',{pretty=>$pretty},$cap,1) if $cap; 

    my ($i,$j,$k,$v);
    # add column names
    my $dsc = (exists $br->{cns_desc}) ? $br->{cns_desc} : {};
        # map { $_ => {name=>ucfirst $_, desc=>ucfirst $_} } 
        # (split /,/, $cn_lst)
    # add column header
    $t .= $s->table_column($cn_lst,$br,$dsc);
    # add data rows
    my $p = {class=>$css_td,attr=>$atr_td,pretty=>$pretty,hr=>{}};
    my $p_tr = {pretty=>$pretty,hr=>{}}; 
    for $i (0 .. $#{$cr}) {
        if ($i%2) { # odd
            $p_tr->{class} = ($css_tr_od) ? $css_tr_od : $css_tr;
            $p_tr->{attr}  = ($atr_tr_od) ? $atr_tr_od : $atr_tr;
        } else {    # even
            $p_tr->{class} = ($css_tr_ev) ? $css_tr_ev : $css_tr;
            $p_tr->{attr}  = ($atr_tr_ev) ? $atr_tr_ev : $atr_tr;
        }
        $t .= $s->html_tag('TR',$p_tr); 
        $j = -1;
        foreach my $k (split /,/,$cn_lst) {
            ++$j;
            $v = $cr->[$i]{$k};
            if ($v && $v =~ /type=["']?input["']?/si) {
                $v =~ s/\<\s*input/\<INPUT class=$css_input /i
                    if $css_input;
                $v =~ s/\<\s*input/\<INPUT $ar_inp->{$k} /i
                    if exists $ar_inp->{$k};
            }
            if ($v && $v =~ /\<\s*select/si) {
                $v =~ s/\<\s*select/\<SELECT class=$css_select /i
                    if $css_select;
                $v =~ s/\<\s*select/\<SELECT $ar_sel->{$k} /i
                    if exists $ar_sel->{$k};
            }
            if (! exists $esc->{$k}) {
                $v =~ s/</\&lt;/g    if $v;
                $v =~ s/>/\&gt;/g    if $v;
            }
            $v = ""              if ! defined($v) || $v =~ /^\s*$/;
            $p->{attr} = ($atr_cell->[$i][$j]) ? 
                "$atr_td $atr_cell->[$i][$j]" : $atr_td;
            if ($cel_title && (exists $cel_title->{"$v"} || 
                exists $cel_title->{"$i:$j"}) ) { 
                $p->{hr}{title}=(exists $cel_title->{"$v"}) ? 
                $cel_title->{"$v"}{desc}:$cel_title->{"$i:$j"}{desc};
                # print "$v: ($i, $j)<br>\n"; 
            } 
            $t .= $s->html_tag('TD',$p,"$v",1);
            $p->{hr}{title} = "";               # reset title attribute
        }
        # $t .= "</TR>\n";
        $t .= $s->html_tag('TR',{pretty=>$pretty},'',1); 
    }
    $t .= "</TABLE>\n";
    if ($ftr) { 
        $t .= $s->html_tag('CENTER',{},$s->html_tag('P',{},$ftr,1),1); 
    }
    my $fh = ($br && exists $br->{fh_out})?$br->{fh_out}:"";
    if ($fh) { print $fh $t; } else { return $t; }
}

=head2 html_tag ($tag, $pr, $txt, $is_end)

Input variables:

  $tag - HTML tag such as TR, TD, TABLE, SELECT, INPUT, etc.
  $pr  - tag attribute array ref. It contains three elements:
    class - CSS class name
    attr  - attribute string such as 'width=5 onChange=js_func'
    hr    - hash ref with key and value pairs
    pretty - whether to add line breaks 
  $txt - text to be incuded between the start and end tag such as
         <TD>$txt</TD>
  $is_end - whether to add an ending tag such as </TD>

Variables used or methods called:

  None

How to use:

  my $t1 = $self->html_tag('TD',{class=>'css_td'},'Text',1);
  # $t1 contains: 
  # <TD class='css_td'>Text</TD>
  my $t2 = $self->html_tag('TD',{class=>'td1',pretty=>1},'Text2',1);
  # $t2 contains: 
  # <TD class='td1'>
  #   Text2
  # </TD>
  my $t3 = $self->html_tag('TD',{class=>'td1',pretty=>1,
    attr=>'colspan=2 align=left',hr=>{onChange=>'js_func'}},
    'Text2',1);
  # $t3 contains: 
  # <TD class='td1' colspan=2 align=left onChange='js_func'>
  #   Text2
  # </TD>

Return: HTML codes.

This method generates HTML codes based on the information provided.

=cut

sub html_tag {
    my $s = shift;
    my ($tag, $pr, $txt, $is_end) = @_;
    $tag = uc $tag;  
    my $tg = lc $tag; 
    my $idt = {tr=>2,td=>4,li=>2,th=>4,caption=>2}; 
    my $t = ""; 
    if ($is_end && !$txt && $tg =~ /^(tr|table|caption)/) {
        $t .= (exists $idt->{$tg}) ? ' 'x$idt->{$tg} : "";
        $t .= "</$tag>\n"     if $is_end; 
        return $t; 
    }
    $t  = (exists $idt->{$tg}) ? ' 'x$idt->{$tg} : ""; 
       $t .= "<$tag"; 
       $t .= " class=$pr->{class}"  
            if $pr && exists $pr->{class} && $pr->{class};
       $t .= " $pr->{attr}"         
            if $pr && exists $pr->{attr} && $pr->{attr};
    if ($pr && exists $pr->{hr} && ref($pr->{hr}) eq 'HASH') {
        map { $t .= " $_='$pr->{hr}{$_}'" } (keys %{$pr->{hr}});
    }
    $t .= ">";
    if ($pr && exists $pr->{pretty} && $pr->{pretty} && 
        $tg !~ /^(td|li)/ ) {
        $t .= "\n"; 
        $t .= "  $txt\n"      if defined($txt) && $txt !~ /^\s*$/; 
        # $t .= (exists $idt->{$tg}) ? ' 'x$idt->{$tg} : ""; 
    } else { 
        $t .= (defined($txt) && $txt !~ /^\s*$/) ? $txt :  
              (($tg =~ /^td/i) ? '&nbsp;' : "");
    }
    if ($is_end) {
        if ($tg !~ /^(td|li|th)/) { 
            $t .= (exists $idt->{$tg}) ? ' 'x$idt->{$tg} : "";
        }
        $t .= "</$tag>\n"     if $is_end; 
    }
    return $t;
}

=head2 table_column ($cn,$pr,$cr)

Input variables:

  $cn - column names separated by comma, or 
    array ref containing column names , or 
    hash ref containing column names as keys
  $pr  - tag attribute array ref. It contains the following items:
    css_tr   - TR class name 
    atr_tr   - TR attributes 
    css_td   - TD class name 
    atr_td   - TD attributes 
    pretty   - whether to add line breaks 
    atr_cell - Cell attribute 
  $cr  - column description hash ref $cr->{$k}{$itm} 
    where $k is column name and the items ($itm) are : 
    desc     - column description
    name     - display name

Variables used or methods called:

  html_tag - generate HTML tags

How to use:

  my $cn = 'seq,fn,ln'; 
  my $pr = {css_tr=>'tr_pretty',css_td=>'td_small',pretty=>1};
  my $cr = {seq=>{name=>'Seq No',desc=>'Sequential number'},
            fn =>{name=>'First Name',desc=>'First name'},
            ln =>{name=>'Last Name',desc=>'Last name/family name'},
    };
  my $t = $self->table_column($cn,$pr,$cr);

Return: HTML codes.

This method generates HTML codes for table header row (TH) 
based on the information provided.

=cut

sub table_column {
    my $s = shift;
    my ($cn,$pr,$cr) = @_; 
    carp "No column names are specified."  if !$cn;
    return if !$cn; 

    my $cns = $cn;
    if (ref($cn) =~ /ARRAY/) {
        $cns = ""; map { $cns .= "$_," } @$cn;      $cns =~ s/,$//;
    } elsif (ref($cn) =~ /HASH/) {
        $cns = ""; map { $cns .= "$_," } keys %$cn; $cns =~ s/,$//;
    } 
    carp "No column names are specified."  if !$cns;
    return if !$cns; 
    my $css_tr    = $s->set_param('css_tr', $pr);
    my $atr_tr    = $s->set_param('atr_tr', $pr);
    my $css_td    = $s->set_param('css_td', $pr);
    my $atr_td    = $s->set_param('atr_td', $pr);
    my $pretty    = $s->set_param('pretty', $pr);
    my $atr_cell  = $s->set_param('atr_cell', $pr);
       $atr_cell  = eval $atr_cell    if $atr_cell;
       $atr_cell  = []                if ! $atr_cell;
    my $esc_vars  = $s->set_param('esc_vars',$pr);
    my $esc = ($esc_vars) ? {  
        map { $_ => 1 } (split /,/,$esc_vars) 
        } : {};
    my $t=$s->html_tag('TR',{class=>$css_tr,attr=>$atr_tr,pretty=>1}); 
    my ($j,$x,$txt) = (-1,$atr_td,"");
    my $p = {class=>$css_td,pretty=>$pretty,hr=>{}};
    foreach my $k (split /,/,$cns) {
        ++$j; $k = lc $k; 
        if ($cr && exists $cr->{$k}{name}) { 
            $txt = $cr->{$k}{name}; 
        } else { 
            $txt = $k; $txt =~ s/_/ /g; 
            $txt = join ' ', (map {ucfirst $_} (split / /, $txt));
        }
        if (! exists $esc->{$k}) {
                $txt =~ s/</\&lt;/g; $txt =~ s/>/\&gt;/g;
        }
        $x = ($x) ? "$x $atr_cell->[0][$j]" : $atr_cell->[0][$j]
            if exists $atr_cell->[0][$j]; 
        $p->{attr} = $x;
        $p->{hr}{title}="$cr->{$k}{name} ($k): $cr->{$k}{desc}" 
            if $cr && exists $cr->{$k} && 
               exists $cr->{$k}{name} && exists $cr->{$k}{desc}; 
        $t .= $s->html_tag('TH',$p,$txt,1);
    }
    $t .= $s->html_tag('TR',{pretty=>$pretty},'',1); 
    # $t .= "</TR>\n";
    return $t;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracts the disp_form method from CGI::Getopt class.

  0.11 Inherited the new constructor from CGI::AppBuilder.
  0.12 Added html_tag and table_column functions 
       Modified html_table to use html_tag and table_column

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
CGI::AppBuilder, CGI::AppBuilder::Message, CGI::AppBuilder::Log,
CGI::AppBuilder::Config, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

