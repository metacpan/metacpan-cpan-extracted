package CGI::AppBuilder::Common;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Path; 
use Net::Rexec 'rexec';
use File::Basename; 

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(new_form disp_task_form disp_help
                   set_args  cc_andwhere 
                   );
our %EXPORT_TAGS = (
    usrforms => [qw(disp_usr_form)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::Common - Create or display Task froms

=head1 SYNOPSIS

  use CGI::AppBuilder::Common;

  my $sec = CGI::AppBuilder::Common->new();


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

sub disp_help {
  my ($s, $ar) = @_;

  my $prg = 'AppBuilder::Common->disp_help'; 
  my $ifn = $s->set_param('ifn', $ar);		# root init file: jp2.txt
  my $ds  = $s->set_param('dir_sep', $ar);	# directory separator
  my $pid = $s->set_param('pid',     $ar);	# project id
  my $tsk = $s->set_param('task',    $ar);	# task name
  my $tmp = $ifn;	$tmp =~ s/\.(\w+)$//;
  my $tf2 = join $ds, $tmp, $pid, "$tsk.txt"; 	# task file name: jp2/ckpt/tsk1.txt
  my $p = {};
  if (! -f $tf2) {
    $s->echo_msg("Warn: ($prg) did not find - $tf2.", 0); 
  } else {
    $p   = $s->read_init_file($tf2); 
  }
  my $k   = "${tsk}_help"; 
  if (! exists $p->{$k}) {
    $s->echo_msg("Warn: ($prg) no help is defined for this task ($tsk).", 1); 
  } else {
    $p->{$k} =~ s/(declare|begin)/$1<br>\n/ig; 
    $p->{$k} =~ s/;/;<br>\n/g; 
    print $p->{$k}; 
  }
  print "</body>\n</html>\n"; 
}

=head2 cc_andwhere ($str,$obj,$typ,$esc)

Input variables:

  $str  - string containing object pattern
  $obj	- object name such as column name
  $typ	- type: where, and or andnot
  $esc  - where to escape the character
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub cc_andwhere {
  my ($s, $str, $obj, $typ, $esc) = @_;

  return "" if !$str || !$obj; 
  $str =~ s/\s*,\s*/','/g; 		# remove space and replace "," with "','"
  $typ = uc $typ; 
  my $whr = ""; 
  if ($typ =~ /^AND$/i) {
    $whr .= "   $typ $obj "; 
  } elsif ($typ =~ /^ANDNOT/i) {
    if (index($str,',') < 0 && index($str,'%') < 0) {
      $whr .= "   AND $obj ";   
    } else {
      $whr .= "   AND $obj NOT ";   
    } 
  } else { 
    $whr .= "  $typ $obj "; 
  } 
  if (index($str,',') > -1 ) {
    $whr .= " IN ('$str') ";
  } elsif (index($str,'%') > -1) {
    $whr .= " LIKE '$str' ";
  } else {
    $whr .= ($typ =~ /^ANDNOT/i) ? " <>  UPPER('$str') " : " =  UPPER('$str') ";
  }
  $whr .= " ESCAPE '$esc' " if ($esc && index($str,'%') > 0);
  return $whr;
}

=head2 new_form ($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History: mm/dd/yyyy (developer) - description

  03/28/2011 (htu) - added $add_check, $f_ir, $f_ip, and $add_test
  04/02/2012 (htu) - added $f_if in new_form
  07/22/2013 (htu) - added id for <tr> and JS:<js_code> type

=cut

sub new_form {
  my ($s, $q, $ar) = @_;

  my $prg = 'AppBuilder::Common->new_form';
  my $tsk = $ar->{new_task}; 				# task: add_study
  my $amg = eval $s->set_param('arg_msgs',$ar); 	# arg msgs
  
  if (exists $ar->{guid}) {
    my ($usr_sid,$usr_uid,$usr_tmo) = split /:/, $ar->{guid}; 
    $ar->{user_sid} = $usr_sid 	if $usr_sid =~ /^\d+$/;
    $ar->{user_uid} = $usr_uid	if $usr_uid;
    $ar->{user_tmo} = $usr_tmo	if $usr_tmo; 
  }
  $ar->{encoding} = 'multipart/form-data' if ($tsk && $tsk =~ /^upload_file/i);

  if (!exists $amg->{$tsk}) {
    $s->echo_msg("ERR: ($prg) could not find new task - $tsk.",0); 
    return; 
  }
  my ($pid,$sid,$t,$t1,$t2) = (); 
     $pid = $ar->{pid} if (exists $ar->{pid} && $ar->{pid}); 
     $sid = $ar->{sid} if (exists $ar->{sid} && $ar->{sid});
     $sid = $ar->{study_id} if (!$sid && exists $ar->{study_id});
     $sid = $ar->{sel_sn1} if (!$sid && exists $ar->{sel_sn1}); 
  my $usr_gid = (exists $ar->{guid}) ? $ar->{guid} : "";      
  my $ksb = eval $s->set_param('var2sub',$ar);     
  my $far = $amg->{$tsk}; 				# form message
  my $cls = eval $s->set_param('code_lists',$ar);	# code lists
 
  my $f_in  = "<input name=\"%s\" value=\"%s\" />"; 
  my $f_ih  = "  <input type=\"hidden\" name=\"%s\" value=\"%s\" />\n"; 
  my $f_ir  = "  <input name=\"%s\" value=\"%s\" readonly/>\n"; 
  my $f_ip  = "  <input type=\"password\" name=\"%s\" value=\"%s\" />\n"; 
  my $f_if  = "  <input type=\"%s\" name=\"%s\" />\n"; 
  my $f_st  = "\n<select name=\"\%s\"  class='formField' %s>\n%s</select>\n  "; 
  my $f_sm  = "\n<select name=\"\%s\"  multiple='multiple' %s>\n%s</select>\n  "; 
  my $f_op  = "  <option value=\"%s\">%s</option>\n"; 
  my $f_os  = "  <option selected value=\"%s\">%s</option>\n";  
  my $f_tr  = "<tr id='%s'>\n  <td>%s</td>\n  <td>%s</td>\n  <td>%s</td>\n</tr>\n"; 
  my $f_tb  = "<table align=center>\n<caption>%s</caption>\n%s\n</table>\n"; 
  my $f_fm  = "<form method=\"$ar->{method}\" action=\"$ar->{action}?\" ";
     $f_fm .= "enctype=\"$ar->{encoding}\" name=\"oraForm\" ";
     $f_fm .= "target=\"%s\">\n%s\n</form>\n";

  my $title = $tsk; $title =~ s/_/ /g; $title = '<b>' . uc($title) . '</b>'; 
  my $add_check = 0;
  my $add_test  = 0; 
  my $test_label = '';
  my $chk_label  = '';

# $s->disp_param($ar);

  for my $i (0..$#$far) {		# each variable
    my $k = $far->[$i][0];		# name/key: study_id
    my $m = $far->[$i][1];		# message
    my $d = $far->[$i][2];		# default value
    my $n = $far->[$i][3];		# desc/required
    my ($k1,$k2) = ($n =~ /^([^:]+):?(.*)?/);
    
    if ($k =~ /^a/i && $n =~ /^check/i) {
      ++$add_check;  $chk_label = ucfirst($n); next; 
    }
    if ($k =~ /^a/i && $n =~ /^test/i) {
      ++$add_test;  $test_label = ucfirst($n); next; 
    }
    if ($n && $n =~ /^hidden/i) {
      $d = (!$d && exists $ar->{$k}) ? $ar->{$k} : $d; 
      $t .= sprintf $f_ih, $k, $d; next; 
    }
    if (exists $ksb->{$k}) {
      my $sub = $ksb->{$k}; 
      my $kkk = $s->$sub($ar); 
      $cls->{$k} = $kkk; 
      # print "Sub: $sub, $k, $kkk<br>\n";       
      # $s->disp_param($cls->{$k});      
    }
    if (exists $cls->{$k}) {		# check code list
      my $a2 = $cls->{$k}; 		# array ref
      $t2 = ''; 
      my $n1 = ($n =~ /^multiple/i) ? 1 : 0; 
      for my $j ($n1..$#$a2) {		# key,value,default?
        # [1		, 'Yes'		, 1],
        my $v0 = $a2->[$j][0]; $v0 =~ s/\n*$//g;
        my $v1 = $a2->[$j][1]; $v1 =~ s/\n*$//g; 
        if (exists $a2->[$j][2] && $a2->[$j][2]) {
          $t2 .= sprintf $f_os, $v0, $v1; 
        } else {
          $t2 .= sprintf $f_op, $v0, $v1; 
        } 
      }
      my $k3 = ($k1 && $k1 =~ /^(js|javascript)/i) ? $k2 : ''; 
      if ($n && $n =~ /^multiple/i) {
        $t1 = sprintf $f_sm, $k, $k3, $t2; 
      } else { 
        $t1 = sprintf $f_st, $k, $k3, $t2; 
      }
      $n = ($k1 && $k1 =~ /^(js|javascript)/i) ? '' : $n; 
    } else { 
      # print "$k = $ar->{$k}<br>\n";     
      my $v = (exists $ar->{$k} && ($ar->{$k}||$ar->{$k} =~ /^\d+$/)) ? $ar->{$k} : '';
         $v = $d	if !$v && $d; 
      # $s->echo_msg("WARN: ($prg) no value provided for $k", 1) if !$v && $n =~/^\*/; 
      if ($n =~ /^readonly/i) {
        $t1 = sprintf $f_ir, $k, $v; 
      } elsif ($n =~ /^(pwd|password)/i) { 
        $t1 = sprintf $f_ip, $k, $v; 
      } elsif ($n =~ /^(js|javacript)/i) { 
        $t1 = sprintf $f_ip, $k, $v; 
      } elsif ($n =~/^(file)/i) { 
        $t1 = sprintf $f_if, $1, $k; 
      } else { 
        $t1 = sprintf $f_in, $k, $v;
      }
# print "n=$n; K1=$k1; K2=$k2\n";       
      $n = ($k2) ? $k2 : (
           ($k1 && $k1 =~ /^(pwd|password|readonly|js|javascript|file)/i) ? '' : $n); 
    } 
    $t .= sprintf $f_tr, "tr_$k", $m, $t1, $n; 
  } 
  
  $t .= "<tr align=center>\n  <td colspan=3>\n";
  $t .= "* indicates required fields"; 
  $t .= "  <input type='submit' name='a' value='Go' />\n";
  $t .= "  <input type='reset' name='.reset' />\n";
  $t .= "  <input type='submit' name='a' value='Help' />\n";
  $t .= "  <input type='submit' name='a' value='$chk_label' />\n" 
        if ($add_check || $tsk =~ /^(run_cptable|run_cfgstudy)/i);
  $t .= "  <input type='submit' name='a' value='$test_label' />\n" 
        if $add_test;        
  $t .= "  </td>\n</tr>\n";
#  $t .= "<tr>\n  <td colspan=3>* indicates required fields</td>\n</tr>\n"; 
  my $tb  = sprintf $f_tb, $title, $t; 
     $t1  = sprintf $f_ih, "pid", $pid 		if $pid || $pid =~ /^0$/;
     $t1 .= sprintf $f_ih, "sel_sn1", $sid	if $sid || $sid =~ /^0$/;
     $t1 .= sprintf $f_ih, "task", $tsk;
     $t1 .= sprintf $f_ih, "no_dispform", 1;
     $t1 .= sprintf $f_ih, "guid", $usr_gid	if $usr_gid;     
  print $q->header("text/html");
  print $q->start_html(%{$ar->{html_header}});
  printf $f_fm, "R", "$t1$tb"; 
  $ar->{bottom_nav} = ''; 
}

=head2 disp_task_form($q,$ar,$txt)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  	pid		: project id such as ckpt, owb, dba, etc.
  	task		: task name required such as task1,task2,etc.
  	target(sel_sn1)	: select one (DB/server name) defining sid
  	args(sel_sn2)	: select two (Arguments)
  	task_fn		: task file name containing all the tasks defined
  	svr_conn	: host/server connection info
  	db_conn		: db connection info for each target/server
  	task_conn	: special connection for tasks. 
  	                  It overwrites db_conn for the task
  
Variables used or routines called:

  None

How to use:


Return: $pr will contain the parameters adn output from running the PL/SQL.


=cut

sub disp_task_form {
  my ($s, $q, $ar, $txt, $ret) = @_;
  
  my $fmn = 'fm1';
     $fmn = $ar->{form_name}
       if exists $ar->{form_name} && $ar->{form_name};
  my %fr = (-name => $fmn, -method=>uc $ar->{method},
      -action=>"$ar->{action}?", -enctype=>$ar->{encoding} );
  if (exists $ar->{hr_form} && $ar->{hr_form}) {
    my $fr_hr = (ref($ar->{hr_form}) =~ /^HASH/) ? 
                $ar->{hr_form} : eval $ar->{hr_form}; 
    foreach my $k (keys %{$fr_hr}) { $fr{$k} = $fr_hr->{$k}; }
  }
  my $t = ""; 
  $t .= $q->start_form(%fr);
  my $hvs = $s->set_param('vars_keep', $ar);
  if ($hvs) {
      foreach my $k (split /,/, $hvs) {
          my $v = $s->set_param($k, $ar);
          next if $v =~ /^\s*$/;
          $t .= $q->hidden($k,$v);
      }
  }
  $t .= "$txt\n";
  $t .= $q->end_form . "\n";
  print  $t if !$ret; 
  return $t if ($ret);
} 


=head2 set_args ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub set_args {
  my ($s, $ar) = @_;

  return if (exists $ar->{sel_sn2} && $ar->{sel_sn2}); 
  
  my $prg = "AppBuilder::Common->set_args";  
  my $tsk = $ar->{task}; 				# task: add_study
  my $amg = eval $s->set_param('arg_msgs',$ar); 	# arg msgs
  my $dir = eval $s->set_param('dir_map',$ar);	 	# dir map
  
  
  if (!exists $amg->{$tsk}) {
    $s->echo_msg("WARN: ($prg) could not find task - $tsk in arg_msgs.",0);  return; 
  }

  my $far = $amg->{$tsk}; 				# form message
  my $sel_sn2 = ''; 
  for my $i (0..$#$far) {		# each variable
    my $k = $far->[$i][0];		# name/key: study_id
    my $m = $far->[$i][1];		# message
    my $d = $far->[$i][2];		# default    
    my $n = $far->[$i][3];		# desc/required
# print "K=$k,M=$m,N=$n<br>\n";     
    if ($n =~ /^\*/ && (!exists $ar->{$k} || !$ar->{$k}) ) {
      $s->echo_msg("ERR: ($prg) $k is required!",0); return; 
    }
    my $v = (exists $ar->{$k}) ? $ar->{$k} : ''; 
    $v =~ s/:/_/g; 
    if ($k =~ /^(dir_name|file_name)/i && exists $ar->{$k}) {
      my ($d1, $d2) = ($v =~ /^(\w_)(.+)/); 
      $d1 = uc $d1; 
      $d2 = dirname($d2) if $k =~ /^(dir_name)/i && $d2 =~ /\.(\w+)$/; 
      $v = $dir->{$d1} . $d2 if exists $dir->{$d1}; 
    }
    $ar->{$k} = $v; 
    $sel_sn2 .= ($i == 0) ? $v : ":$v"; 
  }
#  print "SEL_SN2: $sel_sn2<br>\n";   
  $ar->{sel_sn2} = $sel_sn2; 
} 


1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from jp2.pl on 09/08/2010.

=item * Version 0.20

  09/21/2010 (htu): start this PM
  10/16/2010 (htu): added get_jobid and get_hjobid
    

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::AppBuilder, File::Xcopy,
CGI::AppBuilder::Message

=head1 AUTHOR

Copyright (c) 2009 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

