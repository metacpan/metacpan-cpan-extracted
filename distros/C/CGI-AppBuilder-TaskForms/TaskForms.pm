package CGI::AppBuilder::TaskForms;

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

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(	disp_new form_allin1
                   get_ids get_dblinks get_meddra_version get_iso_version 
                   get_studyid get_jobid get_hjobid get_rids get_htmlrpts
                   );
our %EXPORT_TAGS = (
    usrforms => [qw(disp_usr_form)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::TaskForms - Create or display Task froms

=head1 SYNOPSIS

  use CGI::AppBuilder::TaskForms;

  my $sec = CGI::AppBuilder::TaskForms->new();


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


=head2 disp_new($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_new {
  my ($s, $q, $ar) = @_;
  
  # my $ovs = eval $s->set_param('opf_values', $ar);
  # my $ols = eval $s->set_param('opf_labels', $ar);
  # my $alb = eval $s->set_param('act_labels',$ar); 

  my $arg = eval $s->set_param('arg_required',$ar); 
  
  my ($t, $gf) = ();
  my $ids = $s->get_ids($ar); 
  my $pr  = $s->def_inputvars($ar);
  my $sn  = $pr->{sid}; 			# server id
  my $url = $pr->{web_url};			# web URL
     $url =~ s/(\?.*)//; 			# remove parameters
    $url .= "?pid=ckpt&no_dispform=1&sel_sn1=$pr->{sid}";
  if ($ar->{new_task} =~ /^run_allin1/i) {
    $s->form_allin1($q,$ar); 
  } else {
    $s->new_form($q,$ar);  
  }

} 

=head2 form_allin1 ($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub form_allin1 {
  my ($s, $q, $ar) = @_;

  my $tsk = $ar->{new_task}; 				# task: add_study
  my $amg = eval $s->set_param('arg_msgs',$ar); 	# arg msgs
  
  if (!exists $amg->{$tsk}) {
    $s->echo_msg("ERR: could not find new task - $tsk.",0); 
    return; 
  }
  my ($pid,$sid,$t,$t1,$t2,$t3,$t4,$t_hidden) = (); 
     $pid = $ar->{pid} if (exists $ar->{pid} && $ar->{pid}); 
     $sid = $ar->{sid} if (exists $ar->{sid} && $ar->{sid});
     $sid = $ar->{sel_sn1} if (!$sid && exists $ar->{sel_sn1}); 
  my $ksb = eval $s->set_param('var2sub',$ar);     
  my $far = $amg->{$tsk}; 				# form message
  my $cls = eval $s->set_param('code_lists',$ar);	# code lists
 
  my $f_in  = "<input name=\"%s\" value=\"%s\" />"; 
  my $f_ih  = "  <input type=\"hidden\" name=\"%s\" value=\"%s\" />\n"; 
  my $f_st  = "\n<select name=\"\%s\"  class='formField'>\n%s</select>\n  "; 
  my $f_op  = "  <option value=\"%s\">%s</option>\n"; 
  my $f_os  = "  <option selected value=\"%s\">%s</option>\n";  
  my $f_tr  = "<tr>\n  <td>%s</td>\n  <td>%s</td>\n  <td>%s</td>\n</tr>\n"; 
  my $f_tb  = "<table align=center>\n<caption>%s</caption>\n%s\n</table>\n"; 
  my $f_t2  = "<table align=center valign=top border=1>\n<caption>%s</caption>\n%s\n</table>\n";   
  my $f_fm  = "<form method=\"$ar->{method}\" action=\"$ar->{action}?\" ";
     $f_fm .= "enctype=\"$ar->{encoding}\" name=\"oraForm\" ";
     $f_fm .= "target=\"%s\">\n%s\n</form>\n";

  my $title = $tsk; $title =~ s/_/ /g; $title = '<b>' . uc($title) . '</b>'; 

  my $p = {}; 
  for my $i (0..$#$far) {		# each variable
    my $k = $far->[$i][0];		# name/key: study_id
    my $m = $far->[$i][1];		# message
    my $d = $far->[$i][2];		# default value
    my $n = $far->[$i][3];		# desc/required
    if ($n =~ /^hidden/i) {
      $t_hidden .= sprintf $f_ih, $k, $d; next; 
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
      for my $j (0..$#$a2) {		# key,value,default?
        # [1		, 'Yes'		, 1],
        if (exists $a2->[$j][2] && $a2->[$j][2]) {
          $t2 .= sprintf $f_os, $a2->[$j][0], $a2->[$j][1]; 
        } else {
          $t2 .= sprintf $f_op, $a2->[$j][0], $a2->[$j][1]; 
        } 
      }
      $t1 = sprintf $f_st, $k, $t2; 
    } else { 
      my $v = (exists $ar->{$k} && $ar->{$k}) ? $ar->{$k} : '';
         $v = $d	if !$v && $d; 
      $t1 = sprintf $f_in, $k, $v; 
    } 
    $p->{$k} = sprintf $f_tr, $m, $t1, $n; 
  } 
  $t  = "$p->{study_id}$p->{cpt_src_obj}$p->{cpt_exl_obj}";
  $t1 = sprintf $f_tb, "<b>Copy Tables</b>", $t;
  $t  = "$p->{meta_type}$p->{cfg_exl_obj}";
  $t2 = sprintf $f_tb, "<b>Configure Study</b>", $t;
  $t  = "$p->{chk_job_id}$p->{job_name}$p->{job_desc}$p->{rule_version}";
  $t .= "$p->{sel_list}$p->{exl_list}";
  $t3 = sprintf $f_tb, "<b>Define Check Job</b>", $t;
  $t  = "$p->{meddra_version}$p->{iso_version}";
  $t .= "$p->{email_addr}$p->{rpt_dir}";
  $t4 = sprintf $f_tb, "<b>Define Misc Parameters</b>", $t;
  
  # put it into another table
  $t  = "<tr valign=top><td>$t1\n<td>$t2\n<td>$t3\n<td>$t4\n</tr>";
  $t .= "<tr align=center>\n  <td colspan=4>\n";
  $t .= "* indicates required fields"; 
  $t .= "  <input type='submit' name='a' value='Go' />\n";
  $t .= "  <input type='reset' name='.reset' />\n";
  $t .= "  <input type='submit' name='a' value='Help' />\n";
  $t .= "  <input type='submit' name='a' value='Check' />\n" 
        if $tsk =~ /^(run_cptable|run_cfgstudy|run_allin1)/i;
  $t .= "  </td>\n</tr>\n";
#  $t .= "<tr>\n  <td colspan=3>* indicates required fields</td>\n</tr>\n"; 
  my $tb  = sprintf $f_t2, $title, $t; 
     $t_hidden .= sprintf $f_ih, "pid", $pid 		if $pid;
     $t_hidden .= sprintf $f_ih, "sel_sn1", $sid	if $sid;
     $t_hidden .= sprintf $f_ih, "task", $tsk;
     $t_hidden .= sprintf $f_ih, "no_dispform", 1;
  printf $f_fm, "R", "$t_hidden$tb"; 
  $ar->{bottom_nav} = ''; 
}


=head2 get_ids ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_ids {
  my ($s, $ar) = @_;

  my $r = {}; 				# result array
  my $vs = 'cln_id,cln_name,prj_id,prj_name,study_id,study_name';
    $vs .= ',job_id,job_name,hjob_id,id_type'; 
  foreach my $k (split /,/,$vs) { 
    $r->{$k} = $ar->{$k} if exists $ar->{$k} && ($ar->{$k}||$ar->{$k}=~/^0$/);
  }
  
  # get ids from input field
  if ($ar->{id_type} && exists $ar->{sel_sn2} && ($ar->{sel_sn2} 
    || $ar->{sel_sn2} =~ /^0$/)) { 
    if ($ar->{id_type} =~ /^hjobid/i) {
      $r->{hjob_id} = $ar->{sel_sn2}	if !$r->{hjob_id} || $r->{hjob_id} != 0; 
    } elsif ($ar->{id_type} =~ /^jobid/i) {
      $r->{job_id} = $ar->{sel_sn2} 	if !$r->{job_id} || $r->{job_id} != 0;  
    } elsif ($ar->{id_type} =~ /^clientid/i) {
      $r->{cln_id} = $ar->{sel_sn2} 	if !$r->{cln_id} || $r->{cln_id} != 0;  
    } elsif ($ar->{id_type} =~ /^prjid/i) {
      $r->{prj_id} = $ar->{sel_sn2} 	if !$r->{prj_id} || $r->{prj_id} != 0;  
    } else {
      $r->{study_id} = $ar->{sel_sn2} if !$r->{study_id}||$r->{study_id} != 0; 
    }
  } 
  # assign the values back to $ar 
  foreach my $k (split /,/, $vs) { 
    $ar->{$k} = (exists $r->{$k} && ($r->{$k} || $r->{$k} =~ /^0$/)) ? $r->{$k} : ''; 
  }

  wantarray ? $r : %$r; 
}

=head2 get_iso_version ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_iso_version {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr = 'group by version order by version'; 
  my $rr = $s->run_sqlcmd($ar,'version','comply3chk.CC_ISO3166_1_ALPHA3', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    my $k = $rr->[$i]{version};
    my $v = $k;
    if ($i == $#$rr) {
      push @$r, [$k,$v,1];
    } else {
      push @$r, [$k,$v,0];
    }
  }
  # $s->disp_param($r); 
  unshift @$r, ['', '__Select__',0]; 

  wantarray ? @$r : $r; 
}


=head2 get_rids ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_rids {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr = 'group by rule_id order by rule_id'; 
  my $rr = $s->run_sqlcmd($ar,'rule_id','CC_RULES', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    my $k = $rr->[$i]{rule_id};
    my $v = $k;
    if ($i == $#$rr) {
      push @$r, [$k,$v,0];
    } else {
      push @$r, [$k,$v,0];
    }
  }
  # $s->disp_param($r); 
  unshift @$r, ['', '__Select__',1]; 

  wantarray ? @$r : $r; 
}


=head2 get_meddra_version ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_meddra_version {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr = 'group by version order by to_number(version)'; 
  my $rr = $s->run_sqlcmd($ar,'version','cc_meddra_pt', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    my $k = $rr->[$i]{version};
    my $v = sprintf "%3.1f", $k;
    if ($i == $#$rr) {
      push @$r, [$k,$v,1];
    } else {
      push @$r, [$k,$v,0];
    }
  }
  # $s->disp_param($r); 
  unshift @$r, ['', '__Select__',0]; 

  wantarray ? @$r : $r; 
}


=head2 get_studyid ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_studyid {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr = 'order by study_id'; 
  my $rr = $s->run_sqlcmd($ar,'study_id,study_name','cc_studies', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    push @$r, [$rr->[$i]{study_id},$rr->[$i]{study_name},0];
  }
  unshift @$r, ['', '__Select__',1]; 

  wantarray ? @$r : $r; 
}

=head2 get_jobid ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_jobid {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr  = "where upper(job_action) = 'RUN CHECKS' ";
     $whr .= "and study_id = $ar->{study_id}" 
             if exists $ar->{study_id} && $ar->{study_id};
     $whr .= ' order by job_id'; 
  my $rr = $s->run_sqlcmd($ar,'job_id,job_name','cc_jobs', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    push @$r, [$rr->[$i]{job_id},$rr->[$i]{job_name},0];
  }
  unshift @$r, ['0', '__Select__',1]; 

  wantarray ? @$r : $r; 
}

=head2 get_hjobid ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_hjobid {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $jr = $s->get_jobid($ar); 
  my $jids = ""; 
  for my $i (0..$#$jr) { $jids .= ($jids) ? ",$jr->[$i][0]" : $jr->[$i][0]; }
  
  my $whr  = "where job_id in ($jids)";
     $whr .= ' order by hjob_id'; 
  my $cns  = 'hjob_id,job_starttime,job_endtime,job_status';
  my $rr = $s->run_sqlcmd($ar,$cns,'cc_hist_jobs', $whr);
  # $s->disp_param($rr);  
  my $hid_flag = 0; 
  for my $i (0..$#$rr) {
    my $v  = "$rr->[$i]{job_starttime}/$rr->[$i]{job_endtime}";
       $v .= "/$rr->[$i]{job_status}";
    if (exists $ar->{hjob_id} && $ar->{hjob_id} == $rr->[$i]{hjob_id}) {
      $hid_flag = 1;
      push @$r, [$rr->[$i]{hjob_id},$v,1];
    } else {
      push @$r, [$rr->[$i]{hjob_id},$v,0];
    }
  }
  if ($hid_flag) {
    unshift @$r, ['', '__Select__',0]; 
  } else {
    unshift @$r, ['', '__Select__',1]; 
  }
  wantarray ? @$r : $r; 
}

=head2 get_dblinks ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_dblinks {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr = ''; 
  my $rr = $s->run_sqlcmd($ar,'db_link,username,host','user_db_links', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    my $k = $rr->[$i]{db_link};  $k =~ s/\.\w+//g; 
    my $v = "$rr->[$i]{username}\@$rr->[$i]{host}";
    push @$r, [$k,$v,0];
  }
  # $s->disp_param($r); 
  my $sr = [];
  @$sr = sort { $a->[1] cmp $b->[1] } @$r;
  unshift @$sr, ['', '__Select__',1]; 

  wantarray ? @$sr : $sr; 
}


=head2 get_htmlrpts ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_htmlrpts {
  my ($s, $ar) = @_;

  my $k = 'study_id'; 
  my $f_sid = (exists $ar->{$k} && $ar->{$k} =~ /^\d+$/) ? 1 : 0;
     $k = 'job_id'; 
  my $f_jid = (exists $ar->{$k} && $ar->{$k} =~ /^\d+$/) ? 1 : 0;
  my $jtp  = 'HTMLRPT';
  my $study_id = ($f_sid) ? $ar->{study_id} : '';
  my $pid = (exists $ar->{pid}) ? $ar->{pid} : '';
  my $sn  = (exists $ar->{sid}) ? $ar->{sid} : '';
     $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
     $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  my $drv = (exists $ar->{drv_map}) ? $ar->{drv_map} : '';
     $drv = '\\\\$sn'		if ! $drv;   
  my $ds  = (exists $ar->{dir_sep}) ? $ar->{dir_sep} : '';
     $ds  = ($^O =~ /^MSWin/i) ? '\\' : '/' 	if ! $ds; 
  my $odr = eval $s->set_param('out_dir', $ar); 		# output dir     
  my $dsp = (exists $odr->{$sn}{dsp}) ? $odr->{$sn}{dsp} : $ar->{script_url};	# dsp url
  $dsp .= '?' . "pid=$pid&target=$sn&task=disp_file&f=";
  
  my $whr  = "where job_type = '$jtp' ";
  if ($f_jid) {
     $whr .= " and job_id = $ar->{job_id} "; 
  } else { 
     $whr .= "  and job_id in (select job_id from cc_jobs ";
     $whr .= "where job_action = '$jtp' ";
     $whr .= ($f_sid) ? "  and study_id = $ar->{study_id} ) " : " ) ";
  } 
     $whr .= "order by hjob_id"; 

  my $sql = "ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';\n";
  $sql .= "SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;\n";
  $sql .= "SELECT '==,'||hjob_id||','||job_status||','||job_endtime";
  $sql .= "||','||replace(job_src,',','#') as record ";
  $sql .= "FROM cc_hist_jobs $whr; \n"; 
  $s->echo_msg("SQL: $sql", 3);
  my $rst  = $s->open_cmd($sql,$ar); 
  my $vr = ['hjob_id','job_status','job_endtime','job_src']; 
  $ar->{var_arf} = $vr; 
  my $rr  = $s->parse_records($rst, $vr, '==', ','); 

  my $dft = "%Y%m%d.%H%M%S"; 
  for my $i (0..$#$rr) {
    $rr->[$i]{job_src} =~ s/\#/,/g; 
    my $src = $rr->[$i]{job_src};
    my $sta = $rr->[$i]{job_status};
    my ($dir) = ($src =~ m/dir\=([^\,]+)\,/i); 
    my ($url) = ($src =~ m/url\=([^\,]+)\,/i); 
    my ($ofn) = ($src =~ m/ofn\=([^\,]+)\,/i); 
    my $fn = join $ds, $dir, $ofn;
    my $f2 = $fn; $f2 =~ s/\w\:/$drv/i;
    my ($sid, $jid, $hid, $hms) = ($ofn =~ m/rpt(\d+)_(\d+)_(\d+)_(\d+)/);  
    my $et = $rr->[$i]{job_endtime}; 
    $rr->[$i]{fn2} = $f2; 
    $rr->[$i]{dir} = (defined $dir) ? $dir : '';
    $rr->[$i]{url} = (defined $url) ? $url : '';
    $rr->[$i]{ofn} = (defined $ofn) ? $ofn : '';
    $rr->[$i]{sid} = $sid;
    $rr->[$i]{jid} = $jid;
    $rr->[$i]{hid} = $hid;
    $rr->[$i]{hms} = $hms;
    my $r2 = {}; 
    if (! -f $f2) {
      $r2 = {dsp=>"$dsp$f2",ctm=>'',rtm=>$et,fn=>$fn,t=>$sta};
    } else {
      my @b = stat "$f2"; 
      my $ctm = ($b[9]) ? (strftime $dft, localtime($b[9])) : '';
      my $tit = "$sta - " . (sprintf "S%03dJ%04dH%05d", $sid, $jid, $hid);
      $r2 = {dsp=>"$dsp$f2",ctm=>$ctm,rtm=>$et,fn=>$fn,t=>$tit};
    }
    $rr->[$i]{stat} = $r2; 
  }
  wantarray ? @$rr : $rr; 
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

