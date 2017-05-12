package CGI::AppBuilder::Tasks;

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
our @EXPORT_OK   = qw(disp_usr_task task_url task_usr_input disp_cpsj
                   );
our %EXPORT_TAGS = (
    tasks => [qw(disp_usr_task task_url task_usr_input disp_cpsj)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::PLSQL - Oracle PL/SQL Procedures

=head1 SYNOPSIS

  use CGI::AppBuilder::Tasks;

  my $sec = CGI::AppBuilder::PLSQL->new();
  my ($sta, $msg) = $sec->exe_sql($ar); 

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

=head2 disp_usr_task($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_usr_task {
  my ($s, $q, $ar) = @_;
  my $ovs = eval $s->set_param('opf_values', $ar);
  my $ols = eval $s->set_param('opf_labels', $ar);
  my $alb = eval $s->set_param('act_labels',$ar); 
  my $ids = $s->get_ids($ar); 
  
  my ($t, $gf) = ();
  my $sp4 = "&nbsp;&nbsp;&nbsp;&nbsp;";

  my $f_op = "  <option value=\"%s\">%s</option>\n";
  my $f_li = "  <li><a href=\"%s\">%s</a></li>\n";
  my $f_in = "  <input name=\"%s\" value=\"%s\" type=\"%s\" />\n"; 
  my $f_ih = "  <input type=\"hidden\" name=\"%s\" value=\"%s\" />\n"; 
  my $f_bb = "<b>%s</b>\n"; 
  my $f_aa = "<a href=\"%s\" target=R>%s</a>\n"; 
  my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n"; 
  my $f_fm = "<form method=\"$ar->{method}\" action=\"$ar->{action}?\" ";
    $f_fm .= "enctype=\"$ar->{encoding}\" name=\"oraForm\" target=\"%s\">\n";
    $f_fm .= "$sp4 %s\n</form>\n";

  my $pr  = $s->def_inputvars($ar);
  my $pid = $pr->{pid}; 			# project id: ckpt, dba, owb			
  my $sn  = $pr->{sid}; 			# server id
  my $url = $pr->{web_url};			# web URL
    $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
  if (!$pid) {
    $s->echo_msg("ERR: PID has not been defined.",0); return; 
  }
  my $url4frd = {}; 
     $url4frd = eval $ar->{url4frd} if exists $ar->{url4frd} && $ar->{url4frd}; 

  my $id = 'cln_id'; 
  my $f_cid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0; 
     $id = 'prj_id'; 
  my $f_pid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
     $id = 'study_id'; 
  my $f_sid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
     $id = 'job_id'; 
  my $f_jid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
     $id = 'hjob_id'; 
  my $f_hid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
  
  my $u9a  = "$url&task=disp_cpsj";
     $u9a .= "&cln_id=$ar->{cln_id}"		if $f_cid; 
     $u9a .= "&prj_id=$ar->{prj_id}"		if $f_pid; 
     $u9a .= "&study_id=$ar->{study_id}"	if $f_sid; 
     $u9a .= "&job_id=$ar->{job_id}"		if $f_jid; 
     $u9a .= "&hjob_id=$ar->{hjob_id}"		if $f_hid; 
     $u9a .= "&client_name=$ar->{client_name}"	if exists $ar->{client_name};
     $u9a .= "&cln_name=$ar->{cln_name}"	if exists $ar->{cln_name};
     $u9a .= "&prj_name=$ar->{prj_name}"	if exists $ar->{prj_name};
     $u9a .= "&study_name=$ar->{study_name}"	if exists $ar->{study_name};
     $u9a .= "&job_name=$ar->{job_name}"	if exists $ar->{job_name};
  my $s9a  = sprintf $f_a2, $u9a	, "D"	,"Expand panel tree to left"	,"Expand->"; 
  
  $t .= "<p align=right>$sp4 $s9a</p><hr>\n"; 
  
  # 1 - DB: <b>VP   on VPAPP2</b><br>
  if (!$sn) { 
    $gf = '<select name="sel_sn1" class="formField" >\n';
    for my $i (0..$#$ovs) { $gf .= sprintf $f_op, $ovs->[$i], $ols->{$ovs->[$i]}; }
    $gf .= "</select>\n"; 
    $gf .= "<input name=\"a\" value=\"Go\" type=\"submit\">\n";
    $t .= $s->disp_task_form($q,$ar,$gf,1); 
  } else {
     $t .= "1. DB: <b>$ols->{$sn}</b><br>\n"; 
  } 
  # 2 - Client:
  my $u2a = "$url&task=sel_client&sel_sn2=%"; 
  my $u2b = "$url&task=disp_client"; 
  my $u2c = "$url&task=disp_new&new_task=add_client";
  my $u2d = "$url&a=help&task=add_client"; 
  my $t2b = "D1"; 
  if ( exists $url4frd->{$sn} && $url4frd->{$sn} ) {
     $u2b = $url4frd->{$sn};
     $t2b = "D"; 
  } 
  my $s2a = sprintf $f_a2, $u2a, "R", "Show All Clients", "S";
  my $s2b = sprintf $f_a2, $u2b, $t2b,"Expand to CLIENT", "E"; 
  my $s2c = sprintf $f_a2, $u2c, "D", "Add a client"	, "<b>A</b>";
  my $s2d = sprintf $f_a2, $u2d, "R", "Disp Help"	, "H";
  my $t2t = "2. Client:"; 
  if ($f_cid) {
     $t .= "$t2t [$s2a|$s2c|$s2d|$s2b]<br>\n"; 
     $t .= "$sp4 CID: <b>$ar->{cln_id} - $ar->{cln_name}</b><br>\n"; 
  } else {
    $t .= "$t2t [$s2a|$s2c|$s2d|$s2b]<br>\n";
    $gf = $s->task_usr_input($ar, $pr, 'clientid'); 
    $t .= sprintf $f_fm, "_self", $gf; 
  }
  # 3 - Project:
  my $t3t = "3. Project:"; 
  my $s3p1 = "&task=sel_project";
  my $m3a  = "Show ";
  if ($f_cid) { 
    $s3p1 .= "&sel_sn2=$ar->{cln_id}:%"; 
    $m3a  .= "projects for Client $ar->{cln_id}"; 
  } else { 
    $s3p1 .= "&sel_sn2=:%";
    $m3a  .= "all projects"; 
  }
  my $u3a = "$url$s3p1";
  my $u3b = "$url&task=disp_new&new_task=add_project";
    $u3b .= "&cln_id=$ar->{cln_id}" 	if $ar->{cln_id};
  my $u3c = "$url&task=disp_project"; 
  my $u3d = "$url&a=help&task=add_project"; 
  my $s3a = sprintf $f_a2, $u3a, "R" , $m3a		, "S";
  my $s3b = sprintf $f_a2, $u3b, "D" , "Add a project"	, "<b>A</b>";
  my $s3c = sprintf $f_a2, $u3c, "D2", "Expand projects", "E"; 
  my $s3d = sprintf $f_a2, $u3d, "R",  "Disp Help"	, "H";
  my $s3p2 = $t3t; 
  if ($f_cid) {
    $s3p2 .= "[$s3a|$s3b|$s3d]<br>\n"; 
  } else { 
    $s3p2 .= "[Show|$s3d]<br>\n"; 
  }
  if ($f_pid) {
    $t .= $s3p2 . "$sp4 PID: <b>$ar->{prj_id} - $ar->{prj_name}</b><br>\n"; 
  } else {
    $gf = $s->task_usr_input($ar, $pr, 'prjid'); 
    $t .= $s3p2 . sprintf $f_fm, "_self", $gf; 
  }
  # 4 - Study:
  my $t4t = "4. Study:";   
  my $s4p1  = "&task=sel_study";
  my $m4a  = "Show ";
  if ($f_pid) { 
    $s4p1 .= "&sel_sn2=$ar->{prj_id}:%"; 
    $m4a  .= "studies for Project $ar->{prj_id}"; 
  } else { 
    $s4p1 .= "&sel_sn2=:%"; 
    $m4a  .= "all studies"; 
  }
  my $m4g  = "Show Jobs for Study " . (($f_sid) ? $ar->{study_id} : 'n/a');  
  my $m4h  = "Show H Jobs for Study " . (($f_sid) ? $ar->{study_id} : 'n/a');  
  my $u4a  = "$url$s4p1";
  my $u4b  = "$url&task=disp_new&new_task=add_study"; 
     $u4b .= "&prj_id=$ar->{prj_id}" 	if $ar->{prj_id};
  my $u4c  = "$url&task=disp_study"; 
  my $u4d  = "$url&a=help&task=add_study"; 
  my $u4e  = "$url&task=disp_new&new_task=add_dblink"; 
     $u4e .= "&study_id=$ar->{study_id}"	if $ar->{study_id}; 
  my $u4f  = "$url&a=help&task=add_dblink"; 
  my $u4g  = "$url&task=sel_job";		# web URL
     $u4g .= "&sel_sn2=$ar->{study_id}"		if $f_sid;
  my $u4h  = "$url&task=sel_hjobbysid";		# web URL
     $u4h .= "&sel_sn2=$ar->{study_id}"		if $f_sid;
  my $u4i  = "$url&task=sel_dblink&sel_sn2=" 
            . (($f_sid) ? "%:$ar->{study_id}" : '%');
  
  my $s4a  = sprintf $f_a2, $u4a, "R" ,$m4a		, "SS";
  my $s4b  = sprintf $f_a2, $u4b, "D" ,"Add a study"	, "<b>A</b>";
  my $s4c  = sprintf $f_a2, $u4c, "D3","Expand studies"	, "E";
  my $s4d  = sprintf $f_a2, $u4d, "R" ,"AddStudy Help"	, "H1";
  my $s4e  = sprintf $f_a2, $u4e, "D" ,"Add a dblink"	, "LK";
  my $s4f  = sprintf $f_a2, $u4f, "R" ,"AddDBLink Help"	, "H2";
  my $s4g  = sprintf $f_a2, $u4g, "R" ,$m4g		, "SJ";  
  my $s4h  = sprintf $f_a2, $u4h, "R" ,$m4h		, "SH";  
  my $s4i  = sprintf $f_a2, $u4i, "R" ,"Show DB Links"	, "SL";  
  my $s4k  = ($ar->{cln_id}) ? "&cln_id=$ar->{cln_id}" : ''; 
     $s4k .= "&prj_id=$ar->{prj_id}"		if $ar->{prj_id}; 
     
  my $s4p2 = $t4t; 
  if ($f_pid) {
    $s4p2 .= "[$s4b|$s4c|$s4e]<br>\n"; 
  } else {
    $s4p2 .= "[Show|$s4d|$s4f|$s4i]<br>\n"; 
  } 
  if ($f_sid) {
    $t .= $s4p2 . "$sp4 SID: <b>$ar->{study_id} - $ar->{study_name}</b><br>\n"; 
    $t .= "$sp4 Show: [$s4a|$s4g|$s4h|$s4i]<br>\n";
    $t .= "$sp4 Help: [$s4d|$s4f]<br>\n";
  } else {
    $gf = $s->task_usr_input($ar, $pr, 'studyid'); 
    $t .= $s4p2 . sprintf $f_fm, "_self", $gf; 
  }

  # 5 - CPTABLE 
  my $t5t  = "5. Data: "; 
  my $u5a  = "$url&task=run_cptable";		# web URL
  my $u5b  = "$url&task=disp_new&new_task=run_cptable";
  my $u5c  = "$url&a=help&task=run_cptable"; 
  my $u5d  = "$url&task=disp_new&new_task=run_schcptcfg";
  my $u5dh = "$url&a=help&task=run_schcptcfg"; 
  my $u5e  = "$url&task=disp_new&new_task=run_droptable";
  my $u5eh = "$url&a=help&task=run_droptable";
  my $u5f  = "$url&task=ld_mdrstd"; 
  my $u5fh = "$url&a=help&task=ld_mdrstd";  

  if ($f_sid) { 
     $u5a .= "&sel_sn2=$ar->{study_id}";
     $u5b .= "&study_id=$ar->{study_id}";
     $u5d .= "&study_id=$ar->{study_id}";
     $u5e .= "&study_id=$ar->{study_id}";
     $u5f .= "&study_id=$ar->{study_id}&v=3";     
  } 
  my $m5d = "Select objects to be copied and configured";
  my $s5a  = sprintf $f_a2, $u5a, "R", "Copy All Final Tables"	,"All"; 
  my $s5b  = sprintf $f_a2, $u5b, "D", "Select Tables to be copied","<b>CP</b>"; 
  my $s5c  = sprintf $f_a2, $u5c, "R" ,"CPTable Help"		,"H1";  
  my $s5d  = sprintf $f_a2, $u5d, "D", $m5d			,"CC"; 
  my $s5dh = sprintf $f_a2, $u5dh,"R" ,"Copy and Cfg Help"	,"H2";    
  my $s5e  = sprintf $f_a2, $u5e, "D", "Drop Tables"		,"DT"; 
  my $s5eh = sprintf $f_a2, $u5eh,"R", "Drop Tables Help"	,"H3";   
  my $s5f  = sprintf $f_a2, $u5f, "R", "Load MDR Standard"	,"LM";   
  my $s5fh = sprintf $f_a2, $u5fh,"R", "Load MDR Standard Help" ,"H4";   
  if ($f_sid) {
    $t .= "$t5t [$s5b|$s5e";
    $t .= ($sn eq 'cc300b') ? "|$s5f" : '';
    $t .= "]<br>\n";
    $t .= "$sp4 Show: <br>\n";
    $t .= "$sp4 Help: [$s5c|$s5dh|$s5eh|$s5fh]<br>\n";
  } else {
    $t .= "$t5t [All|Sel|$s5c|$s5dh|$s5eh|$s5fh]<br>\n";
  }

  # 6 - CFGSTUDY
  my $t6t = "6. Cfg: "; 
  my $u6a = "$url&task=run_cfgstudy";		# web URL
  my $u6b = "$url&task=disp_new&new_task=run_cfgstudy";
  my $u6c  = "$url&a=help&task=run_cfgstudy"; 
  
  if ($f_sid) { 
     $u6a .= "&sel_sn2=$ar->{study_id}";
     $u6b .= "&study_id=$ar->{study_id}";
  } 
  my $s6a  = sprintf $f_a2, $u6a, "R", "Cfg All Tables"		,"All"; 
  my $s6b  = sprintf $f_a2, $u6b, "D", "Select Tables to cfg"	,"<b>Sel</b>"; 
  my $s6c  = sprintf $f_a2, $u6c, "R" ,"CfgStudy Help"		,"H";  
  if ($ar->{study_id}) {
    $t .= "$t6t [$s6a|$s6b|$s6c]<br>\n";     
  } else {
    $t .= "$t6t [All|Sel|$s6c]<br>\n";     
  }

  # 7 - Job:
  my $t7t = "7. Job:"; 
  my $ur7  = $url;
     $ur7 .= "&sel_sn2=$ar->{study_id}"		if $f_sid;
#    $ur7 .= "&sel_sn2=$ar->{job_id}"		if $f)jid;

  my $u7a  = "$url&task=sel_job";		# web URL
     $u7a .= "&sel_sn2=$ar->{study_id}"		if $f_sid;
  my $u7b  = "$url&task=disp_new&new_task=add_job";
     $u7b .= "&study_id=$ar->{study_id}"	if $f_sid;
  my $u7c  = "$url&task=run_schjob";
     $u7c .= "&study_id=$ar->{study_id}"	if $f_sid;
     $u7c .= "&sel_sn2=$ar->{job_id}"		if $f_jid;
  my $u7bh  = "$url&a=help&task=add_job"; 
  my $u7ch  = "$url&a=help&task=run_schjob"; 
  my $u7d  = "$url&task=sel_hjob";		# web URL
     $u7d .= "&sel_sn2=$ar->{job_id}"		if $f_jid;

  my $m7a  = "Show Jobs for Study " . (($f_sid) ? $ar->{study_id} : 'n/a');
  my $m7d  = "Show H Jobs for Job " . (($f_jid) ? $ar->{job_id} : 'n/a'); 
  my $s7a  = sprintf $f_a2, $u7a	, "R"	, $m7a		, "SJ" ;
  my $s7b  = sprintf $f_a2, $u7b	, "D"	,"Add a Job"	, "<b>A</b>" ;
  my $s7c  = sprintf $f_a2, $u7c	, "R"	,"Run a Job"	, "<b>R</b>" ;
  my $s7bh = sprintf $f_a2, $u7bh	, "R"	,"AddJob Help"	, "H1";  
  my $s7ch = sprintf $f_a2, $u7ch	, "R"	,"RunJob Help"	, "H2";  
  my $s7d  = sprintf $f_a2, $u7d	, "R"	, $m7d		, "SH" ;
  
  my $s7i = $s->task_usr_input($ar, $pr, 'jobid'); 
  my $s7k = ($f_cid) ? "&cln_id=$ar->{cln_id}" : ''; 
    $s7k .= "&prj_id=$ar->{prj_id}"	if $f_pid; 
    $s7k .= "&study_id=$ar->{study_id}"	if $f_sid; 

  my $t7a = "$t7t ["; 
     $t7a .= ($f_sid) ? $s7b : 'Add';
     $t7a .= ($f_jid) ? "|$s7c]<br>\n" : "|Run|$s7bh|$s7ch]<br>\n"; 
  my $t7b = "$sp4 JID: <b>";
    $t7b .= ($f_jid) ? $ar->{job_id} : '';
    $t7b .= (exists $ar->{job_name}) ? " - $ar->{job_name}" : ' - ';
    $t7b .= "</b><br>\n";
  my $t7c = "$sp4 Show: [";
    $t7c .= ($f_jid) ? $s7a : '';     
    $t7c .= ($f_sid) ? "|$s7d" : '';
    $t7c .= "]<br>\n"; 
  my $t7d = "$sp4 Help: [$s7bh|$s7ch]<br>\n";
 
  if ($f_jid) {
    $t .= "$t7a $t7b $t7c $t7d";
  } else {
    $t .= $t7a . (sprintf $f_fm, "_self", "$s7i"); 
  }

  # 8 - Report 
  my $t8t = "8. Report:"; 
  my $u8a  = "$url&task=sel_result";
     $u8a .= "&sel_sn2=$ar->{hjob_id}"		if $ar->{hjob_id};
  my $u8b  = "$url&task=run_htmlrpt";
     $u8b .= "&sel_sn2=$ar->{hjob_id}"		if $ar->{hjob_id};
  my $u8c  = "$url&task=run_xmlrpt";
     $u8c .= "&sel_sn2=$ar->{hjob_id}"		if $ar->{hjob_id};
  my $u8ch = "$url&a=help&task=run_xmlrpt";      
  my $u8d  = "$url&task=sel_hjob";
     $u8d .= "&sel_sn2=$ar->{job_id}"		if $ar->{job_id}; 
  my $u8e  = "$url&task=disp_rpts";    
     $u8e .= "&study_id=$ar->{study_id}"	if $ar->{study_id}; 
  my $u8eh = "$url&a=help&task=disp_rpts";           
  my $u8f  = "$url&task=disp_new&new_task=run_htmlrpt";    
     $u8f .= "&study_id=$ar->{study_id}"	if $ar->{study_id}; 
     $u8f .= "&hjob_id=$ar->{hjob_id}"		if $ar->{hjob_id};      
  my $u8fh = "$url&a=help&task=run_htmlrpt";           
  my $u8g  = "$url&task=disp_hids";    
     $u8g .= "&study_id=$ar->{study_id}"	if $ar->{study_id}; 
  my $u8gh = "$url&a=help&task=disp_hids";                
  my $u8h  = "$url&task=disp_archive";    
     $u8h .= "&study_id=$ar->{study_id}"	if $ar->{study_id}; 
     $u8h .= "&job_id=$ar->{job_id}"		if $ar->{job_id}; 
     $u8h .= "&hjob_id=$ar->{hjob_id}"		if $ar->{hjob_id};      
  my $u8hh = "$url&a=help&task=disp_archive";                
  my $u8i  = "$url&task=disp_new&new_task=run_schhtmlrpt";
     $u8i .= "&study_id=$ar->{study_id}"	if $ar->{study_id}; 
     $u8i .= "&hjob_id=$ar->{hjob_id}"		if $ar->{hjob_id};      
  my $u8ih = "$url&a=help&task=run_schhtmlrpt";                     
  my $u8j  = "$url&task=disp_htmlrpt";    
     $u8j .= "&study_id=$ar->{study_id}"	if $f_sid; 
  
  my $s8a  = sprintf $f_a2, $u8a	, "R"	,"Show Results"		,"S";
  my $s8b  = sprintf $f_a2, $u8b	, "R"	,"Run HTML report"	,"HTML";
  my $s8c  = sprintf $f_a2, $u8c	, "R"	,"Run XML report"	,"XML";
  my $s8ch = sprintf $f_a2, $u8ch	, "R" 	,"Run XMLRPT Help"	,"H2";  
  my $s8d  = sprintf $f_a2, $u8d	, "R"	,"Show HJobs"		,"HJ";
  my $s8e  = sprintf $f_a2, $u8e	, "R"	,"List existing reports","RPT";
  my $s8eh = sprintf $f_a2, $u8eh	, "R" 	,"DispRPTS Help"	,"H3";  
  my $s8f  = sprintf $f_a2, $u8f	, "D"	,"Select and Run HTML reports","Sel";  
  my $s8fh = sprintf $f_a2, $u8fh	, "R" 	,"Run HTMLRPT Help"	,"H1";  
  my $s8g  = sprintf $f_a2, $u8g	, "R"	,"List Hist Job Status","Status";
  my $s8gh = sprintf $f_a2, $u8gh	, "R" 	,"DispHIDs Help"	,"H4";  
  my $s8h  = sprintf $f_a2, $u8h	, "R"	,"Archive Report to Drive O","Arch";
  my $s8hh = sprintf $f_a2, $u8hh	, "R" 	,"DispArchive Help"	,"H5";  
  my $s8i  = sprintf $f_a2, $u8i	, "D"	,"Schedule HTML report"	,"<b>Sch</b>"; 
  my $s8ih = sprintf $f_a2, $u8ih	, "R" 	,"Schedule HTMLRPT Help","H6";    
  my $s8j  = sprintf $f_a2, $u8j	, "R" 	,"Show HTML Reports","SR";      
  my $s8u = $s->task_usr_input($ar, $pr, 'hjobid');      
  if ($f_hid) {
    # $t .= "$t8t [$s8a|$s8i|$s8b|$s8c|$s8d|$s8e|$s8g|$s8h]<br>";
    $t .= "$t8t [$s8i|$s8e|$s8h]<br>";
    $t .= "$sp4 HID: <b>$ar->{hjob_id} - ";
    $t .= ((exists $ar->{job_action}) ? $ar->{job_action} : 'n/a') . "</b><br>\n";
    $t .= "$sp4 Show: [$s8a|$s8d|$s8g|$s8j]<br>\n";
    $t .= "$sp4 Help: [$s8fh|$s8ch|$s8eh|$s8gh|$s8hh|$s8ih]<br>\n";
  } else {
    $t .= "$t8t [$s8g|$s8e|$s8h]<br>";
    $t .= sprintf $f_fm, "_self", $s8u;
  } 

  # 9 - AllInOne
  my $t9t = "9. All In One:"; 
  my $u9b  = "$url&task=disp_new&new_task=run_allin1";
     $u9b .= "&study_id=$ar->{study_id}"	if $ar->{study_id};

  my $s9b  = sprintf $f_a2, $u9b	, "D"	,"Show AllInOne"	,"Show";
  
  $t .= "$t9t ";
  if ($f_sid) { 
    # $t .= "[$s9b]<br><hr>\n";
    $t .= "[ShowAll]<br><hr>\n";
  } else {
    $t .= "One step to submit all jobs<hr>"; 
  }

     
  print $t; 
  return;
} 

sub task_url {
  my ($s, $ar, $pr, $typ) = @_;

  
  $typ = $ar->{id_type} if !$typ && exists $ar->{id_type} && $ar->{id_type};
  $typ = 'studyid'	if !$typ; 
  my ($study_id,$study_name,$job_id,$job_name,$hjob_id) = ();
  $study_id = $ar->{study_id}	if exists $ar->{study_id} && $ar->{study_id};
  $study_id = $ar->{sel_sn2}	if !$study_id 
    && exists $ar->{sel_sn2} && $ar->{sel_sn2} && $typ =~ /^studyid/;
  $job_id   = $ar->{job_id} if exists $ar->{job_id} && $ar->{job_id};
  $hjob_id  = $ar->{hjob_id} if exists $ar->{hjob_id} && $ar->{hjob_id};
  my $pid = $pr->{pid};				# project id
  my $sn  = $pr->{sid}; 			# server id
  my $url = $pr->{web_url};			# web URL
     $url =~ s/(\?.*)//; 			# remove parameters
  my $u1  = "pid=$pid&no_dispform=1"; 
     $u1 .= "&sel_sn1=$pr->{sid}"	if exists $pr->{sid} && $pr->{sid};
     $u1 .= "&study_id=$study_id"	if $study_id;
     $u1 .= "&job_id=$job_id" 		if $job_id;
     $u1 .= "&hjob_id=$hjob_id" 	if $hjob_id;
     $u1 .= "&study_name=$ar->{study_name}"	
          if exists $ar->{study_name} && $ar->{study_name};
     $u1 .= "&job_name=$ar->{job_name}" 
          if exists $ar->{job_name} && $ar->{job_name};
  if ($typ && $typ =~ /(cptable|cfgstudy|recfgsch|cfgschema|studyid)/) {
     $u1 .= "&sel_sn2=$study_id" 	if $study_id; 
  } elsif ($typ && $typ =~ /(schjob|jobid)/i) {
     $u1 .= "&sel_sn2=$job_id"		if $job_id; 
  } elsif ($typ && $typ =~ /(htmlrpt|xmlrpt|hjobid)/i) {
     $u1 .= "&sel_sn2=$hjob_id"		if $hjob_id; 
  }
  return "$url?$u1";
}

=head2

sub form_input_name {
  my ($s, $ar, $id,$tsk) = @_;

  my $fmt = "<input type=\"hidden\" name=\"%s\" value=\"%s\" />\n";
  my $fi2 = "<input name=\"%s\" value=\"%s\" size=5 />\n";
  my $t   = "";
  $t .= sprintf $fmt,"pid", $ar->{pid} 	   if exist $ar->{pid} && $ar->{pid}; 
  $t .= sprintf $fmt,"sel_sn1", $ar->{sid} if exist $ar->{sid} && $ar->{sid}; 
  $t .= sprintf $fmt, "task", $tsk; 
  $t .= sprintf $fmt, $id, $ar->{$id}	   if exists $ar->{$id} && $ar->{$id};
  
  if (exists $ar->{$id} && $ar->{$id}) {
    $t .= sprintf $fi2, "sel_sn2", "$ar->{$id}:";
  } else {
    $t .= sprintf $fi2, "sel_sn2", "";
  } 
 
}

=cut

sub task_usr_input {
  my ($s, $ar, $pr, $typ) = @_;

  $typ = $ar->{id_type} if !$typ && exists $ar->{id_type} && $ar->{id_type};
  $typ = 'studyid'	if !$typ; 


  my $pid = (exists $ar->{pid} && $ar->{pid}) ? $ar->{pid} : '';

  my $id = 'cln_id'; 
  my $f_cid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0; 
     $id = 'prj_id'; 
  my $f_pid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
     $id = 'study_id'; 
  my $f_sid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
     $id = 'job_id'; 
  my $f_jid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
     $id = 'hjob_id'; 
  my $f_hid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/) ? 1 : 0;      
  
  my $cln_id   = ($f_cid) ? $ar->{cln_id}   : '';
  my $prj_id   = ($f_pid) ? $ar->{prj_id}   : '';
  my $study_id = ($f_sid) ? $ar->{study_id} : '';
  my $job_id   = ($f_jid) ? $ar->{job_id}   : '';
  my $hjob_id  = ($f_hid) ? $ar->{hjob_id}  : '';
  
  if (!$pid) {
    $s->echo_msg("ERR: pid is not defined.", 0); return; 
  }

  my $k = '';
  my $fmt = "<input type=\"hidden\" name=\"%s\" value=\"%s\" />\n";
  my $t = sprintf $fmt, "pid", $pid; 
  $t .= sprintf $fmt, "sel_sn1",  $pr->{sid}	if exists $pr->{sid}; 
  $t .= sprintf $fmt, "task",     "disp_usr_task";
  $t .= sprintf $fmt, "id_type",  $typ		if $typ;
  $t .= sprintf $fmt, "cln_id",   $cln_id 	if $f_cid;
  $t .= sprintf $fmt, "prj_id",   $prj_id 	if $f_pid;
  $t .= sprintf $fmt, "study_id", $study_id 	if $f_sid;
  $t .= sprintf $fmt, "job_id",   $job_id 	if $f_jid;
  $t .= sprintf $fmt, "hjob_id",  $hjob_id 	if $f_hid;
  $k  = 'cln_name';
  $t .= sprintf $fmt, "cln_name", $ar->{$k} if exists $ar->{$k} && $ar->{$k};
  $k  = 'prj_name';
  $t .= sprintf $fmt, "prj_name", $ar->{$k} if exists $ar->{$k} && $ar->{$k};
  $k  = 'study_name';
  $t .= sprintf $fmt, "study_name", $ar->{$k} if exists $ar->{$k} && $ar->{$k};
  $k  = 'job_name';
  $t .= sprintf $fmt, "job_name", $ar->{$k} if exists $ar->{$k} && $ar->{$k};

  $t .= uc($typ) . ": <input name=\"sel_sn2\" value=\"\" size=5 />\n" ; 
  $t .= "<input name=\"a\" value=\"Set\" type=\"submit\" />"; 
  return $t;
}

=head2 disp_cpsj($q,$ar)

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

sub disp_cpsj {
  my ($s, $q, $ar) = @_;

  my $prg = 'AppBuilder::Tasks->disp_cpsj';
  my $ids  = 'cln_id,prj_id,study_id,job_id,hjob_id';
     $ids .= ',id_type,study_name,job_name,cln_name,prj_name';
     $ids .= ',client_name'; 
  my $p = {};
  foreach my $k (split /,/, $ids) {
    if ($k =~ /id$/i) { 
      $p->{$k} = (exists $ar->{$k} && $ar->{$k} =~ /^\d+$/) ?
  		$ar->{$k} : ''; 
    } else {
      $p->{$k} = (exists $ar->{$k} && $ar->{$k}) ? $ar->{$k} : ''; 
    }

  }
  my $pr  = $s->def_inputvars($ar);
  my $pid = (exists $pr->{pid} && $pr->{pid}) ? $pr->{pid} : '';      
  if (!$pid) {
    $s->echo_msg("ERR: ($prg) pid is not defined.", 0); return; 
  }

  foreach my $k (split /,/, $ids) {
    $p->{$k} = $pr->{$k} if exists $pr->{$k}; 
  }

  my $k   = 'cln_id'; 
  my $t1  = ($p->{$k} =~ /^\d+$/) ? "&$k=$p->{$k}" : ''; 
     $k   = 'cln_name'; 
     $t1 .= ($p->{$k}) ? "&$k=$p->{$k}" : ''; 
  my $t2 = $t1;      
     $k   = 'prj_id'; 
     $t2 .= ($p->{$k} =~ /^\d+$/) ? "&$k=$p->{$k}" : ''; 
     $k   = 'prj_name'; 
     $t2 .= ($p->{$k}) ? "&$k=$p->{$k}" : ''; 
  my $t3 = $t2;      
     $k   = 'study_id'; 
     $t3 .= ($p->{$k} =~ /^\d+$/) ? "&$k=$p->{$k}" : ''; 
     $k   = 'study_name'; 
     $t3 .= ($p->{$k}) ? "&$k=$p->{$k}" : ''; 
  my $t4 = $t3;      
     $k   = 'job_id'; 
     $t4 .= ($p->{$k} =~ /^\d+$/) ? "&$k=$p->{$k}" : ''; 
     $k   = 'job_name'; 
     $t4 .= ($p->{$k}) ? "&$k=$p->{$k}" : ''; 
#  my $t = '';
#  foreach my $k (split /,/, $ids) {
#    if ($k =~ /id$/i && $k ne 'pid') {
#      $t .= "&$k=$p->{$k}" if $p->{$k} =~ /^\d+$/; 
#    } else {
#      $t .= "&$k=$p->{$k}" if $p->{$k}; 
#    }
#  }

  my $sn  = $pr->{sid}; 			# server id
  my $url = $pr->{web_url};			# web URL
    $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
  my $u1  = "$url&task=disp_client$t1";
  my $u2  = "$url&task=disp_project$t2"; 
  my $u3  = "$url&task=disp_study$t3"; 
  my $u4  = "$url&task=disp_job$t4"; 
  my $f_ht  = "<html>\n<head>\n<link rel=\"canonical\" href=\"%s\" />\n";
     $f_ht .= "<meta http-equiv=\"refresh\" content=\"2; ";
     $f_ht .= "URL=%s\" target=%s>\n";
     $f_ht .= "</head>\n</html>\n"; 

  my $f_fm  = "<html>\n";
     $f_fm .= "<FRAMESET cols='1/4,1/4,1/4,1/4' name='D' frameborder=no ";
     $f_fm .= "border=0 framespacing=0>\n";
     $f_fm .= "<FRAME src='$u1' name='D1'>\n";
     $f_fm .= "<FRAME src='$u2' name='D2'>\n";
     $f_fm .= "<FRAME src='$u3' name='D3'>\n";
     $f_fm .= "<FRAME src='$u4' name='D4'>\n";
     $f_fm .= "</FRAMESET>\n</html>\n"; 
  print "$f_fm"; 
  return; 
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

=cut

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from jp2.pl on 09/08/2010.

=item * Version 0.20

  09/08/2010 (htu): 
    1. start this PM

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

