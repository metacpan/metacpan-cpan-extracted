package CGI::AppBuilder::MapDisps;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use CGI::AppBuilder::HTML qw(:all);
use File::Path; 
use File::Copy;
use File::Basename;
use Archive::Tar; 
use IO::File;
use Net::Rexec 'rexec';

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(disp_new
		   disp_links  build_links disp_map_task
                   disp_client disp_project disp_study disp_list disp_job 
                   disp_cptable disp_rpts disp_tabs disp_hids disp_archive
                   check_tabs check_droptabs check_rentabs disp_logfiles
                   disp_cpsj
                   );
our %EXPORT_TAGS = (
    tasks => [qw(disp_links disp_map_task task_url task_usr_input)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::MapDisps - Display tasks

=head1 SYNOPSIS

  use CGI::AppBuilder::MapDisps;

  my $sec = CGI::AppBuilder::MapDisps->new();
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
  
#  $s->disp_header($q,$ar,1);
  
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
  my $ids  = 'cln_id,prj_id,study_id,list_id,job_id,hjob_id';
     $ids .= ',id_type,study_name,list_name,cln_name,prj_name,job_name';
     $ids .= ',client_name,list_name'; 
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
  my $usr_gid = (exists $ar->{guid}) ? $ar->{guid} : ""; 
  my $ug      = ($usr_gid) ? "&guid=$usr_gid" : ""; 

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
#  my $t4 = $t3;      
#     $k   = 'job_id'; 
#     $t4 .= ($p->{$k} =~ /^\d+$/) ? "&$k=$p->{$k}" : ''; 
#     $k   = 'job_name'; 
#     $t4 .= ($p->{$k}) ? "&$k=$p->{$k}" : ''; 
  my $t4 = $t3;      
     $k   = 'list_id'; 
     $t4 .= ($p->{$k} =~ /^\d+$/) ? "&$k=$p->{$k}" : ''; 
     $k   = 'list_name'; 
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
    $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn$ug";
  my $u1  = "$url&task=disp_client$t1";
  my $u2  = "$url&task=disp_project$t2"; 
  my $u3  = "$url&task=disp_study$t3"; 
  my $u4  = "$url&task=disp_list$t4"; 
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

=head2 check_tabs($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History: 

=cut

sub check_tabs {
  my ($s, $q, $ar) = @_;
  $s->disp_tabs($q,$ar);
}


=head2 check_droptabs($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History: 

=cut

sub check_droptabs {
  my ($s, $q, $ar) = @_;
  
  $s->disp_header($q,$ar,1);
  
  my $prg = 'CGI::AppBuilder::MapDisps->check_droptabs';
  $s->echo_msg("INFO: running $prg ...",1); 
  
  # 1. get variables
  my ($sn,$dbl,$dbl_vars, $study_id,$study_name,$tnm,$xnm) = (); 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 
  my $obj_vars	= (exists $ar->{obj_vars}) ? $ar->{obj_vars} : '';
  if ($obj_vars) {
    foreach my $k (split /,/, $obj_vars) {
      $tnm = uc($ar->{$k}) if exists $ar->{$k} && $ar->{$k}; 
    }
  }
  my $exc_vars = (exists $ar->{exc_vars}) ? $ar->{exc_vars} : ''; 
  if ($exc_vars) { 
    for my $k (split /,/, $exc_vars) {
       $xnm = uc($ar->{$k})	if !$xnm && exists $ar->{$k}; 
    } 
  } 
  $tnm	= uc($ar->{src_obj})		if !$tnm && exists $ar->{src_obj};
  $tnm	= uc($ar->{src_objects})	if !$tnm && exists $ar->{src_objects};
  $tnm  = uc($ar->{cpt_src_obj})	if !$tnm && exists $ar->{cpt_src_obj};
  $tnm	= '%FINAL'			if !$tnm; 
  $xnm	= uc($ar->{exl_objects})	if !$xnm && exists $ar->{exl_objects};
  $xnm	= uc($ar->{src_excl})		if !$xnm && exists $ar->{src_excl};
  $xnm  = uc($ar->{cpt_exl_obj})	if !$xnm && exists $ar->{cpt_exl_obj}; 

  my $fmn = (exists $ar->{fm_name}) ? (uc $ar->{fm_name}) : '';
  my $ton = (exists $ar->{to_name}) ? (uc $ar->{to_name}) : '';

  # 2. check required elements
  if (!$sn) {
    $s->echo_msg("ERR: server name is not defined.", 0);  return; 
  }
  if ($study_id != 0 && !$study_id) {
    $s->echo_msg("ERR: study_id is not provided.", 0);  return; 
  }

  # 3. get study schema and DBL

  my $whr = "where study_id = $study_id order by study_id"; 
  my $cns = 'study_name,stg_schema,stg_dbl,src_schema';
  my $rr = $s->run_sqlcmd($ar,$cns,'sp_studies', $whr);
  
  if ($#$rr < 0) {
    $s->echo_msg("ERR: ($prg) could not find study_id - $study_id in study table.", 0); 
    return;
  }
  $study_name = $rr->[0]{study_name}	if !$study_name;
  my $stg_sch = uc $rr->[0]{stg_schema}; 	$stg_sch =~ s/\s+//g;
  my $stg_dbl = uc $rr->[0]{stg_dbl};		$stg_dbl =~ s/\s+//g;
  my $src_sch = uc $rr->[0]{src_schema}; 	$src_sch =~ s/\s+//g;
  if (!$src_sch ) {
    $s->echo_msg("ERR: ($prg) could not find stg_schema($src_sch).",0); 
    return; 
  }
  $s->echo_msg("INFO: ($prg) STG_SCH=$stg_sch, STG_DBL=$stg_dbl,SRC_SCH=$src_sch", 3); 

  # 4. get all tables from staging schema
  my $task = (exists $ar->{task}) ? (uc $ar->{task}) : ''; 
  if ($task eq 'RUN_RENTABLE') {
    $fmn = 'SOURCE'	if ! $fmn;
    $ton = 'FINAL'	if ! $ton; 
  }
  my $r = {}; 						# result array ref
  my ($wh1,$wh2,$r1,$r2) = ();

  # get number of rows for the tables  
  # $wh1  = $s->cc_andwhere($stg_sch,  'owner', 'where'); 
  my $stn = '%' . $fmn . '%'; 
  $wh1  = $s->cc_andwhere($src_sch,  'owner', 'where'); 
  $wh1 .= $s->cc_andwhere($tnm, 'table_name', 'and'); 
  $wh1 .= $s->cc_andwhere($stn, 'table_name', 'and')		if $fmn; 
  $wh1 .= $s->cc_andwhere($xnm, 'table_name', 'andnot'); 
  $r1   = $s->run_sqlcmd($ar,'table_name,num_rows','all_tables', $wh1);
  # $wh2  = $s->cc_andwhere($stg_sch,      'owner', 'where'); 
  $wh2  = $s->cc_andwhere($src_sch,      'owner', 'where'); 
  $wh2 .= $s->cc_andwhere('TABLE', 'object_type', 'and'); 
  $wh2 .= $s->cc_andwhere($tnm   , 'object_name', 'and'); 
  $wh2 .= $s->cc_andwhere($stn   , 'object_name', 'and')	if $fmn;   
  $wh2 .= $s->cc_andwhere($xnm   , 'object_name', 'andnot'); 
  $r2   = $s->run_sqlcmd($ar,'object_name,last_ddl_time','all_objects', $wh2);
  $s->echo_msg("WH1=$wh1; WH2=$wh2",3);     
  for my $i (0..$#$r1) {
    my $k = $r1->[$i]{table_name}; 
    $r->{$k} = {}	if !exists $r->{$k}; 
    $r->{$k}{t_rows} = $r1->[$i]{num_rows}; 
  }
  for my $i (0..$#$r2) {
    my $k = $r2->[$i]{object_name}; 
    $r->{$k} = {}	if !exists $r->{$k}; 
    $r->{$k}{t_time} = $r2->[$i]{last_ddl_time}; 
  }

  # 5. build html
  my $actn = ($task eq 'RUN_RENTABLE') ? 'renamed' : 'dropped';
  my $f_th  = "  <tr><th>%s\n      <th>%s\n      <th>%s\n  </tr>\n";
  my $f_tr  = "  <tr class=%s><td>%s\n      <td>%s\n      ";
     $f_tr .= "<td align=right>%s\n  </tr>\n";
  my $rec_cnt = 0; 
  my $t  = "<font color=red>$task: The following tables will be <b>$actn</b> ";
     $t .= "if you click the <b>Go</b> button:</font> <br><br>\n"; 
     $t .= "<table>\n"; 
     $t .= "<caption>Tables In Study $study_id - $study_name<br>";
     $t .= "($src_sch;$tnm;$xnm;$fmn;$ton)</caption>\n"; 
     $t .= sprintf $f_th, "Table Name", "DDL Time", "Num of Rows"; 
  my @rec = (); 
  foreach my $k (sort keys %$r) {
    $rec_cnt += 1; 
    my @rec = ();
    push @rec, (($rec_cnt % 2 == 0) ? 'even' : 'odd'); 
    push @rec, $k; 
    foreach my $j (split /,/,'t_time,t_rows') {
      push @rec,((!exists $r->{$k}{$j}) ? '<b>N/A</b>' : 
        (($r->{$k}{$j})?$r->{$k}{$j}:'&nbsp;'));
    } 
    $t .= sprintf $f_tr, @rec; 
  }
  $t .= "</table>\n";
  $t .= "<b>Total $rec_cnt records.</b>\n";
  
  # 6. print html
  
  if (! $rec_cnt) {
    my $m = "ERR: ($prg) no src table is found for Study $study_id ";
       $m .= "($src_sch;$tnm;$xnm;$fmn;$ton).<br>$wh2"; 
    $s->echo_msg($m, 0); 
    return; 
  }
  print $t;
  return;
} 

sub check_rentabs {
  my ($s, $q, $ar) = @_;
  return $s->check_droptabs($q, $ar); 
}

=head2 disp_map_task($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History: 
  08/28/2013 (htu): - 
    1. added code to only show USS and ASJ if the user role is dev
    2. display run_setanypwd if user role is adm

=cut

sub disp_map_task {
  my ($s, $q, $ar) = @_;
  
  my $prg = 'disp_map_task';
  my $ovs = eval $s->set_param('opf_values', $ar);
  my $ols = eval $s->set_param('opf_labels', $ar);
  my $alb = eval $s->set_param('act_labels',$ar); 
  my $usr_rls = (exists $ar->{usr_roles}) ? (eval $ar->{usr_roles}) : {};
  my $rls = {}; 
  foreach my $k (keys %$usr_rls) {
    for my $i (0..$#{$usr_rls->{$k}}) {
      my $u = $usr_rls->{$k}[$i];
      $rls->{$k}{$u} = 1; 
    }
  }
  
  # my $ids = $s->get_ids($ar); 
  
  my ($t, $gf) = ();

  print $s->disp_header($q, $ar);

  my $f_op = "  <option value=\"%s\">%s</option>\n";
  my $f_li = "  <li><a href=\"%s\">%s</a></li>\n";
  my $f_in = "  <input name=\"%s\" value=\"%s\" type=\"%s\" />\n"; 
  my $f_ih = "  <input type=\"hidden\" name=\"%s\" value=\"%s\" />\n"; 
  my $f_bb = "<b>%s</b>\n"; 
  my $f_aa = "<a href=\"%s\" target=R>%s</a>\n"; 
  my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n"; 
  my $f_fm = "<form method=\"$ar->{method}\" action=\"$ar->{action}?\" ";
    $f_fm .= "enctype=\"$ar->{encoding}\" name=\"oraForm\" target=\"%s\">\n";
    $f_fm .= "%s\n</form>\n";

  my $pr  = $s->def_inputvars($ar);
  my $pid = $pr->{pid}; 			# project id: ckpt, dba, owb			
  my $sn  = $pr->{sid}; 			# server id

  $s->set_ids($ar); 
  my $vs = 'user_sid,user_uid,user_tmo,guid';
  my ($usr_sid,$usr_uid,$usr_tmo,$usr_gid) = $s->get_params($vs, $ar);
  
  my $url = $pr->{web_url};			# web URL
    $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
    $url .= (exists $ar->{logout} && $ar->{logout}) ? "" : "&guid=$usr_gid";
    
  if (!$pid) {
    $s->echo_msg("ERR: ($prg) PID has not been defined.",0); return; 
  }
  if (!$sn) {
    $s->echo_msg("ERR: ($prg) SID has not been defined.",0); return;   
  } 
  my $url4frd = {}; 
     $url4frd = eval $ar->{url4frd} if exists $ar->{url4frd} && $ar->{url4frd}; 

  my $sp4 = "&nbsp;&nbsp;&nbsp;&nbsp;";

  my $id = 'cln_id'; 
  my $f_cid = (!exists $ar->{$id} || !defined($ar->{$id}) || $ar->{$id} !~ /^\d+$/) ? 0 : 1; 
     $id = 'prj_id'; 
  my $f_pid = (!exists $ar->{$id} || !defined($ar->{$id}) || $ar->{$id} !~ /^\d+$/) ? 0 : 1;     
     $id = 'study_id'; 
  my $f_sid = (!exists $ar->{$id} || !defined($ar->{$id}) || $ar->{$id} !~ /^\d+$/) ? 0 : 1;     
     $id = 'job_id'; 
  my $f_jid = (!exists $ar->{$id} || !defined($ar->{$id}) || $ar->{$id} !~ /^\d+$/) ? 0 : 1;      
     $id = 'hjob_id'; 
  my $f_hid = (!exists $ar->{$id} || !defined($ar->{$id}) || $ar->{$id} !~ /^\d+$/) ? 0 : 1;     
     $id = 'list_id'; 
  my $f_lid = (!exists $ar->{$id} || !defined($ar->{$id}) || $ar->{$id} !~ /^\d+$/) ? 0 : 1;  
    
  my $u9a  = "$url&task=disp_cpsj";
     $u9a .= "&cln_id=$ar->{cln_id}"		if $f_cid; 
     $u9a .= "&prj_id=$ar->{prj_id}"		if $f_pid; 
     $u9a .= "&study_id=$ar->{study_id}"	if $f_sid; 
     $u9a .= "&job_id=$ar->{job_id}"		if $f_jid; 
     $u9a .= "&hjob_id=$ar->{hjob_id}"		if $f_hid; 
     $u9a .= "&list_id=$ar->{list_id}"		if $f_lid;      
     $u9a .= "&client_name=$ar->{client_name}"	if exists $ar->{client_name};
     $u9a .= "&cln_name=$ar->{cln_name}"	if exists $ar->{cln_name};
     $u9a .= "&prj_name=$ar->{prj_name}"	if exists $ar->{prj_name};
     $u9a .= "&study_name=$ar->{study_name}"	if exists $ar->{study_name};
     $u9a .= "&job_name=$ar->{job_name}"	if exists $ar->{job_name};
     $u9a .= "&list_name=$ar->{list_name}"	if exists $ar->{list_name};     
  my $s9a  = sprintf $f_a2, $u9a	, "D"	,"Expand panel tree to left"	,"Expand->"; 
  
  $t .= "<p align=right>$sp4 $s9a</p><hr>\n"	if $f_cid && $f_pid && $f_sid && $f_lid; 
 
  # 1 - DB: <b>VP   on VPAPP2</b><br>
  my $u1a = "$url&task=disp_new&new_task=run_adduser"; 
  my $u1b = "$url&task=disp_new&new_task=run_login"; 
  my $u1c = "$url&task=disp_new&new_task=run_logout"; 
  my $u1d = "$url&task=disp_new&new_task=run_chgpwd"; 
  my $u1e = "$url&task=disp_new&new_task=run_setpwd";   
  my $u1f = "$url&task=disp_new&new_task=run_setanypwd"; 

  my $s1a = sprintf $f_a2, $u1a, "R", "Add a User"	, "AddUsr";
  my $s1b = sprintf $f_a2, $u1b, "R", "Login User"	, "Login";
  my $s1c = sprintf $f_a2, $u1c, "R", "Logout User"	, "Logout";  
  my $s1d = sprintf $f_a2, $u1d, "R", "Change User's PWD", "ChgPWD";  
  my $s1e = sprintf $f_a2, $u1e, "R", "Set to Default PWD", "SetPWD";    
     $s1e = sprintf $f_a2, $u1f, "R", "Set Anyone to Default PWD", "SetPWD"     
            if exists $rls->{adm}{$usr_uid};
  if (!$sn) { 
    $gf = '<select name="sel_sn1" class="formField" >\n';
    for my $i (0..$#$ovs) { $gf .= sprintf $f_op, $ovs->[$i], $ols->{$ovs->[$i]}; }
    $gf .= "</select>\n"; 
    $gf .= "<input name=\"a\" value=\"Go\" type=\"submit\">\n";
    $t .= $s->disp_task_form($q,$ar,$gf,1); 
  } else {
     $t .= "1. DB: <b>$ols->{$sn}</b><br>\n"; 
     $t .= "$sp4 [";
     $t .= "$s1a|"  if exists $rls->{adm}{$usr_uid};
     $t .= "$s1b|$s1c|$s1d|$s1e]<br>\n";
  } 
  # 2 - Client:
  my $u2a = "$url&task=sel_client&sel_sn2=%"; 
#  my $u2b = "$url&task=disp_client"; 
  my $u2b = "$url&task=disp_frd";   
  my $u2c = "$url&task=disp_new&new_task=add_client";
  my $u2d = "$url&a=help&task=add_client"; 
  my $t2b = "D"; 
#  if ( exists $url4frd->{$sn} && $url4frd->{$sn} ) {
#     $u2b = $url4frd->{$sn};
#     $t2b = "D"; 
#  } 
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
    $u3b .= "&cln_id=$ar->{cln_id}" 	if $f_cid;
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
    $gf = $s3p2 . $s->task_usr_input($ar, $pr, 'prjid'); 
    $t .= sprintf $f_fm, "_self", $gf; 
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
  my $u4a  = "$url$s4p1";
  my $u4b  = "$url&task=disp_new&new_task=add_study"; 
     $u4b .= "&prj_id=$ar->{prj_id}" 	if $ar->{prj_id};
  my $u4c  = "$url&task=disp_study"; 
  my $u4d  = "$url&a=help&task=add_study"; 
  my $u4e  = "$url&task=disp_new&new_task=add_dblink"; 
     $u4e .= "&study_id=$ar->{study_id}"	if $f_sid; 
  my $u4f  = "$url&a=help&task=add_dblink"; 
  my $u4g  = "$url&task=disp_new&new_task=run_cptable"; 
     $u4g .= "&study_id=$ar->{study_id}"	if $f_sid; 
  my $u4h  = "$url&a=help&task=run_cptable"; 
  my $u4i  = "$url&task=disp_new&new_task=run_droptable";
     $u4i .= "&study_id=$ar->{study_id}"	if $f_sid; 
  my $u4ih = "$url&a=help&task=run_droptable"; 
  my $u4j  = "$url&task=disp_new&new_task=run_rentable";
     $u4j .= "&study_id=$ar->{study_id}"	if $f_sid;   
  my $u4jh = "$url&a=help&task=run_rentable"; 

  my $u4k1  = "$url&task=disp_new&new_task=upload_sas_script";
     $u4k1 .= "&study_id=$ar->{study_id}"	if $f_sid; 
     $u4k1 .= "&list_id=$ar->{list_id}"		if $f_lid; 

  my $u4k  = "$url&task=disp_new&new_task=add_ldrsasjob";
     $u4k .= "&study_id=$ar->{study_id}"	if $f_sid; 
     $u4k .= "&list_id=$ar->{list_id}"		if $f_lid; 
  my $u4kh = "$url&a=help&task=add_ldrsasjob"; 
  my $u4l  = "$url&task=sel_sasjob";
     $u4l .= "&study_id=$ar->{study_id}"	if $f_sid; 
  
  my $s4a  = sprintf $f_a2, $u4a, "R" ,$m4a		, "S";
  my $s4b  = sprintf $f_a2, $u4b, "D" ,"Add a study"	, "<b>A</b>";
  my $s4c  = sprintf $f_a2, $u4c, "D3","Expand studies"	, "E";
  my $s4d  = sprintf $f_a2, $u4d, "R" ,"AddStudy Help"	, "H1";
  my $s4e  = sprintf $f_a2, $u4e, "R" ,"Add a dblink"	, "L";
  my $s4f  = sprintf $f_a2, $u4f, "R" ,"AddDBLink Help"	, "H2";
  my $s4g  = sprintf $f_a2, $u4g, "R" ,"Run CPTABLE"	, "C";
  my $s4h  = sprintf $f_a2, $u4h, "R" ,"Help on CPTABLE", "H3";
  my $s4i  = sprintf $f_a2, $u4i, "R", "Drop Tables"	, "D";     
  my $s4ih = sprintf $f_a2, $u4ih,"R" ,"Drop Table Help", "H4";
  my $s4j  = sprintf $f_a2, $u4j, "R", "Rename Tables"	, "R";       
  my $s4jh = sprintf $f_a2, $u4jh,"R" ,"Rename Table Help","H5";  
  my $s4k1 = sprintf $f_a2, $u4k1,"R", "Upload SAS Script","USS";         
  my $s4k  = sprintf $f_a2, $u4k, "R", "Add a SAS Job"	, "ASJ";       
  my $s4kh = sprintf $f_a2, $u4kh,"R" ,"LOADSAS Help"	,"H6";  
  my $s4l  = sprintf $f_a2, $u4l, "R" ,"Show SASJob"	,"SJ";    
  
#  my $s4k  = ($f_cid) ? "&cln_id=$ar->{cln_id}" : ''; 
#     $s4k .= "&prj_id=$ar->{prj_id}"		if $f_pid; 
  my $s4p2 = $t4t; 
  
  if ($f_pid) {
    # $s4p2 .= "[$s4a|$s4d|$s4f|$s4b|$s4e]<br>\n"; 
    $s4p2 .= "[$s4a|$s4b|$s4e|$s4g|$s4i|$s4j";
    $s4p2 .= "|$s4k1|$s4k"  		if exists $rls->{dev}{$usr_uid};
    $s4p2 .= "]<br>\n"; 
    $s4p2 .= "$sp4 Help: [$s4d|$s4f|$s4h|$s4ih|$s4jh|$s4kh]<br>\n";
  } else {
    $s4p2 .= "[Show|$s4d|$s4f]<br>\n"; 
  } 
  if ($ar->{study_id}) {
    $t .= $s4p2 . "$sp4 SID: <b>$ar->{study_id} - $ar->{study_name}</b><br>\n"; 
  } else {
    $gf = $s4p2 . $s->task_usr_input($ar, $pr, 'studyid'); 
    $t .= sprintf $f_fm, "_self", $gf; 
  }

  # 5 - Load XLS 
  my $t5t  = "5. Load: "; 
  my $u5a  = "$url&task=sel_spec";		# web URL
  my $u5b  = "$url&task=disp_new&new_task=run_ldspecs";
  my $u5bh = "$url&a=help&task=run_ldspecs"; 
  my $u5c  = "$url&task=disp_new&new_task=upload_file";
  my $u5ch = "$url&a=help&task=upload_file"; 
  my $u5d  = "$url&task=disp_new&new_task=sel_spec";
  my $u5e  = "$url&task=disp_new&new_task=run_ldviews";
  my $u5eh = "$url&a=help&task=run_ldviews";   
  my $u5f  = "$url&task=disp_new&new_task=sel_codes";
  my $u5g  = "$url&task=disp_logfiles";    
  my $u5h  = "$url&task=disp_new&new_task=run_crtviews";
  my $u5hh = "$url&a=help&task=run_crtviews";   
  
  if ($f_sid) { 
     $u5a .= "&sel_sn2=$ar->{study_id}";
     $u5b .= "&study_id=$ar->{study_id}";     
     $u5c .= "&study_id=$ar->{study_id}";
     $u5d .= "&study_id=$ar->{study_id}";  
     $u5e .= "&study_id=$ar->{study_id}";  
  } 
  if ($f_lid) { 
     $u5a .= "&sel_sn2=$ar->{list_id}";
     $u5b .= "&list_id=$ar->{list_id}";     
     $u5c .= "&list_id=$ar->{list_id}";
     $u5d .= "&list_id=$ar->{list_id}";     
     $u5e .= "&list_id=$ar->{list_id}";
     $u5f .= "&list_id=$ar->{list_id}";
     $u5g .= "&list_id=$ar->{list_id}";
     $u5h .= "&list_id=$ar->{list_id}";     
  } 
  my $s5a  = sprintf $f_a2, $u5a, "R", "Show Specs for all the domains"	,"S"; 
  my $s5b  = sprintf $f_a2, $u5b, "R", "Load Specs from XLS","<b>LS</b>"; 
  my $s5c  = sprintf $f_a2, $u5c, "R", "UpLoad Specs file","<b>UL</b>";   
  my $s5bh = sprintf $f_a2, $u5bh,"R" ,"XLSLoad Help"	,"H1";  
  my $s5d  = sprintf $f_a2, $u5d, "D", "Select Specs"	,"SS"; 
  my $s5e  = sprintf $f_a2, $u5e, "R", "Load View Codes from XLS","<b>LV</b>"; 
  my $s5eh = sprintf $f_a2, $u5eh,"R" ,"LoadView Help"	,"H2"; 
  my $s5f  = sprintf $f_a2, $u5f, "D" ,"Select Codes"	,"SV"; 
  my $s5g  = sprintf $f_a2, $u5g, "R" ,"Disp LogFiles"	,"LF"; 
  my $s5h  = sprintf $f_a2, $u5h, "R" ,"Create Views"	,"<b>CV</b>"; 
  my $s5hh = sprintf $f_a2, $u5hh,"R" ,"CrtView Help"	,"H3";   

  if ($f_lid) {
    $t .= "$t5t [$s5c|$s5b|$s5e|$s5h]<br>\n";
    $t .= "$sp4 Show: [$s5a|$s5d|$s5f|$s5g]<br>\n";
    $t .= "$sp4 Help: [$s5bh|$s5eh|$s5hh]<br>\n";
  } else {
    $t .= "$t5t [Show|Help|$s5bh|$s5eh|$s5hh]<br>\n";
  }

  # 6 - Add a Job
  my $t6t = "6. Job: "; 
  my $u6a = "$url&task=disp_new&new_task=add_job";
  my $u6b = "$url&task=disp_new&new_task=run_job";
  my $u6c = "$url&a=help&task=add_job"; 
  my $u6d = "$url&a=help&task=run_job"; 
  my $u6e = "$url&task=sel_job";
  my $u6f = "$url&task=disp_logfiles";  
  
  if ($f_lid) { 
     $u6a .= "&list_id=$ar->{list_id}";
     $u6b .= "&list_id=$ar->{list_id}";
     $u6e .= "&sel_sn2=$ar->{list_id}";
     $u6f .= "&list_id=$ar->{list_id}";
  } 
  if ($f_jid) {
     $u6f .= "&job_id=$ar->{job_id}";  
  }
  my $s6a  = sprintf $f_a2, $u6a, "R", "Add a Job"		,"Add"; 
  my $s6b  = sprintf $f_a2, $u6b, "D", "Run a Job"		,"Run"; 
  my $s6c  = sprintf $f_a2, $u6c, "R" ,"Help on Add_aJob"	,"H1";  
  my $s6d  = sprintf $f_a2, $u6d, "R" ,"Help on Run_aJob"	,"H2";  
  my $s6e  = sprintf $f_a2, $u6e, "R" ,"Display Jobs"		,"S";  
  my $s6f  = sprintf $f_a2, $u6f, "R" ,"Display LogFiles"	,"LF";    
  if ($ar->{list_id}) {
    $t .= "$t6t [$s6a|$s6b|$s6c|$s6d|$s6e|$s6f]<br>\n";     
  } else {
    $t .= "$t6t [Add|Run|$s6c|$s6d|$s6f]<br>\n";     
  }
  # 7 - Execute:
  my $t7t = "7. Execute:"; 
  my $s7p2 = $t7t; 
  my $ur7  = $url;
     $ur7 .= "&sel_sn2=$ar->{study_id}"		if $f_sid;
#    $ur7 .= "&sel_sn2=$ar->{job_id}"		if $f_jid;

  my $u7a  = "$url&task=sel_job";		# web URL
     $u7a .= "&sel_sn2=$ar->{study_id}"		if $f_sid;
  my $u7b  = "$url&task=disp_new&new_task=add_job";
     $u7b .= "&study_id=$ar->{study_id}"	if $f_sid;
  my $u7c  = "$url&task=run_schjob";
     $u7c .= "&study_id=$ar->{study_id}"	if $f_sid;
     $u7c .= "&sel_sn2=$ar->{job_id}"		if $f_jid;
  my $u7d  = "$url&a=help&task=add_job"; 
  my $u7e  = "$url&a=help&task=run_schjob"; 
  my $m7a  = "Show ";
     $m7a .= "jobs for Study $ar->{study_id}"	if $f_sid; 
  my $s7a = sprintf $f_a2, $u7a	, "R"	, $m7a		, "S" ;
  my $s7b = sprintf $f_a2, $u7b	, "D"	,"Add a Job"	, "A" ;
  my $s7c = sprintf $f_a2, $u7c	, "R"	,"Run a Job"	, "R" ;
  my $s7d = sprintf $f_a2, $u7d	, "R"	,"AddJob Help"	, "H1";  
  my $s7e = sprintf $f_a2, $u7e	, "R"	,"RunJob Help"	, "H2";  
  
  my $s7i = $s->task_usr_input($ar, $pr, 'jobid'); 
  my $s7k = ($f_cid) ? "&cln_id=$ar->{cln_id}" : ''; 
    $s7k .= "&prj_id=$ar->{prj_id}"	if $f_pid; 
    $s7k .= "&study_id=$ar->{study_id}"	if $f_sid; 
  $s7p2 .= '['; 
#  if ($ar->{study_id}) {
#    $s7p2 .= "$s7a|$s7d|$s7e|$s7b";     
#  } else { 
    $s7p2 .= "Show|$s7d|$s7e|Add";     
#  } 
  if ($f_jid) {
    $s7p2 .= "|$s7c]<br>";
#    $t .= $s7p2 . "JID: <b>$ar->{job_id} - $ar->{job_name}</b><br>\n"; 
  } else {
    $s7p2 .= "|Run]<br>"; 
#    $t .= (sprintf $f_fm, "_self", "$s7p2 $s7i"); 
  }
  # 8 - Report 
  my $t8t = "8. Report:"; 
  my $u8a  = "$url&task=sel_result";
     $u8a .= "&sel_sn2=$ar->{hjob_id}"		if $f_hid;
  my $u8b  = "$url&task=run_htmlrpt";
     $u8b .= "&sel_sn2=$ar->{hjob_id}"		if $f_hid;
  my $u8c  = "$url&task=run_xmlrpt";
     $u8c .= "&sel_sn2=$ar->{hjob_id}"		if $f_hid;
  my $u8d  = "$url&task=sel_hjob";
     $u8d .= "&sel_sn2=$ar->{job_id}"		if $f_jid; 
  my $u8e  = "$url&task=disp_rpts";    
     $u8e .= "&study_id=$ar->{study_id}"	if $f_sid; 
  my $u8f  = "$url&task=disp_new&new_task=run_htmlrpt";    
     $u8f .= "&study_id=$ar->{study_id}"	if $f_sid; 
     $u8f .= "&hjob_id=$ar->{hjob_id}"		if $f_hid;      
  my $u8g  = "$url&task=disp_hids";    
     $u8g .= "&study_id=$ar->{study_id}"	if $f_sid; 
  my $u8h  = "$url&task=disp_archive";    
     $u8h .= "&study_id=$ar->{study_id}"	if $f_sid; 
     $u8h .= "&job_id=$ar->{job_id}"		if $f_jid; 
     $u8h .= "&hjob_id=$ar->{hjob_id}"		if $f_hid;      
  my $s8a  = sprintf $f_a2, $u8a	, "R"	,"Show Results"		,"S";
  my $s8b  = sprintf $f_a2, $u8b	, "R"	,"Run HTML report"	,"HTML";
  my $s8c  = sprintf $f_a2, $u8c	, "R"	,"Run XML report"	,"XML";
  my $s8d  = sprintf $f_a2, $u8d	, "R"	,"Show HJobs"		,"HJ";
  my $s8e  = sprintf $f_a2, $u8e	, "R"	,"List existing reports","RPT";
  my $s8f  = sprintf $f_a2, $u8f	, "D"	,"Select and Run HTML reports","Sel";  
  my $s8g  = sprintf $f_a2, $u8g	, "R"	,"List Hist Job Status","Status";
  my $s8h  = sprintf $f_a2, $u8h	, "R"	,"Archive Report to Drive O","Arch";
  my $s8u = $s->task_usr_input($ar, $pr, 'hjobid');      
#  if ($ar->{hjob_id}) {
#    $t .= "$t8t [$s8a|$s8f|$s8b|$s8c|$s8d|$s8e|$s8g|$s8h]<br>";
#    $t .= "HID: <b>$ar->{hjob_id} - $ar->{job_name}</b><br>\n";
#  } else {
#    $t .= "$t8t [$s8g|$s8e|$s8h]<br>";
#    $t .= sprintf $f_fm, "_self", $s8u;
#  } 

  print $t; 
  return;
} 


=head2 disp_archive($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_archive {
  my ($s, $q, $ar) = @_;
  
  $s->disp_header($q,$ar,1);
  
  # 1. get variables
  $s->echo_msg("1. get variables", 2); 
  my ($sn,$odr,$adr,$rdr,$dsp,$css_style,$dsp_owb,$dsp_dir,$rpt_kp) = (); 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $adr = "$ar->{arch_dir}/$sn" 	if exists $ar->{arch_dir};
  $odr = eval $s->set_param('out_dir', $ar); 			# output dir
  $rdr = $odr->{$sn}{rpt};  					# rpt dir
  $dsp = $odr->{$sn}{dsp};					# dsp url
  $css_style = $ar->{css_style}	if exists $ar->{css_style}; 
  $dsp_owb   = $ar->{dsp_owb}	if exists $ar->{dsp_owb}; 
  $dsp_dir   = $ar->{dsp_dir}	if exists $ar->{dsp_dir}; 
  $rpt_kp    = $ar->{rpt_keep}	if exists $ar->{rpt_keep};	# seconds 

  my ($study_id,$job_id,$hjob_id,$jid,$hid,$study_name) = (); 
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 
  $job_id 	= $ar->{job_id}		if exists $ar->{job_id};
  $hjob_id 	= $ar->{hjob_id}	if exists $ar->{hjob_id};

  $s->echo_msg("INFO: RDR - $rdr<br>\nDSP - $dsp",3);

  # 2. check required elements
  $s->echo_msg("2. check required variables", 2); 
  if (! -d $ar->{arch_dir}) {
    $s->echo_msg("ERR: could not find archive dir - $ar->{arch_dir}.", 0);  return; 
  }
  $s->echo_msg("mkpath: $adr", 2);      
  eval { mkpath($adr) };
  $s->echo_msg("ERR: couldn't create $adr: $@", 0) if ($@);

  if (! -d $rdr) {
    $s->echo_msg("ERR: could not find rpt dir - $rdr.", 0);  return; 
  }

  # 3. get study id
  $s->echo_msg("3. get study id and name", 2); 
  my $studyid = $s->get_studyid($ar); 			# study ids
  my $sd = {};						# study id hash array
  for my $i (0..$#$studyid) { 
    $sd->{$studyid->[$i][0]} = $studyid->[$i][1];
  }

  # 4. get all index files  
  $s->echo_msg("4. get all index files", 2); 
  my $fname = 'index';
  opendir DD, "$rdr" or die "ERR: could not opendir - $rdr: $!\n";
  my @a = sort grep !/\.bak$/, (grep /$fname/, readdir DD);
  closedir DD;

  # 5. loop through each file
  $s->echo_msg("5. build index file array", 2); 
  my $r = {}; 						# result array ref
  my $rpt_cnt = 0;
  for my $i (0..$#a) {
    my ($sid, $jid, $hid, $hms) = ($a[$i] =~ m/rpt(\d+)_(\d+)_(\d+)_(\d+)/); 
    next if $study_id 	&& $study_id != $sid; 
    next if $job_id  	&& $job_id   != $jid; 
    next if $hjob_id  	&& $hjob_id  != $hid; 
    $rpt_cnt += 1; 
    my @b = stat "$rdr/$a[$i]"; 
    my $ctm = strftime "%Y/%m/%d %H:%M:%S", localtime($b[9]);
    my $tit = sprintf "S%03dJ%04dH%05d", $sid, $jid, $hid;
    my $sub = sprintf "S%05d/J%05d/H%05d/%d", $sid, $jid, $hid, $hms;
    my $sb2 = sprintf "S%05d\\J%05d\\H%05d\\%d", $sid, $jid, $hid, $hms;
    $r->{$sid} = [] if !exists $r->{$sid}; 
    push @{$r->{$sid}}, {dsp=>"$dsp/$a[$i]",ctm=>$ctm,fn=>$a[$i],t=>$tit,
      rdr=>$rdr,adr=>$adr, sub=>$sub,ffn=>"$rdr/$a[$i]",
      dsp_owb=>"$dsp_owb/$sn/$sub", ptm=>$b[9], 
      dsp_dir=>"$dsp_dir\\$sn\\$sb2",
      };
    # print "$a[$i] - $sid:$jid:$hid:$hms:$ctm<br>\n"; 
  }
  # $s->disp_param($r);

  # 6. archive the reports
  $s->echo_msg("6. archive reports", 2); 
  foreach my $k (sort keys %$r) {
    for my $i (0..$#{$r->{$k}}) {
      my $p   = $r->{$k}[$i]; 
      my $tm1 = $p->{ptm}; 
      my $rd  = $p->{rdr};
      my $sd  = $p->{sub};
      my $ffn = $p->{ffn};
      my $fn  = $p->{fn};
      my $dr  = "$adr/$sd";
      my $ofn = "$adr/$sd/$fn"; 
      # 6.1 check if the target file exist and older than current on
      if (-f $ofn) {
        my $tm2 = (stat $ofn)[9]; 
        if ($tm2 > $tm1) {  
          $s->echo_msg("INFO: $fn - skipped.", 3); 
          next; 
        }
      }
      # 6.2 make target dir
      if (!-d $dr) { 
        $s->echo_msg("mkpath: $dr", 3);      
        eval { mkpath($dr) };
        $s->echo_msg("ERR: couldn't create $dr: $@", 0) if ($@);
      } 
      # 6.3 copy the css style file to the target folder
      copy $css_style, $dr	if $css_style; 

      # 6.4 open the index file and target file
      open IDX, "<$ffn" or croak "ERR: could not open file - $ffn: $!\n";
      open OFN, ">$ofn" or croak "ERR: could not write to file - $ofn: $!\n";
      while (<IDX>) {
        my $rec = $_; 
        # href="http://ors2di/cgi/dsp.pl?t=vpapp2&f=logs/rpts/rpt92_287_646_115805_10268.htm"
        if ($rec =~ m/\"(http:.+\/)(.+)\"/) {
          my ($f1, $ifn2, $ofn2) = ($2, "$rdr/$2", "$adr/$sd/$2"); 
          $rec =~ s/\"(http:.+\/)(.+)\"/\"$f1\"/; 
          $s->echo_msg("INFO: copying $ifn2 to $ofn2",4);          
          # copy($ifn2,$ofn2); 
          open IFN2, "<$ifn2" or croak "ERR: could not open - $ifn2: $!\n"; 
          open OFN2, ">$ofn2" or croak "ERR: could not write to $ofn2: $!\n";
          while (<IFN2>) { 
            if ($_ =~ m/(href\=\"\/styles\/)/ ) {
              $_ =~ s/(href\=\"\/styles\/)/href\=\"/;
            } 
            print OFN2 $_; 
          }
          close IFN2;
          close OFN2;
        } elsif ($rec =~ m/(href\=\"\/styles\/)/ ) {
          # <link rel="stylesheet" type="text/css" href="/styles/dfcommon.css" />
          $rec =~ s/(href\=\"\/styles\/)/href\=\"/;
        } elsif ($rec =~ m/(href\=\"mailto:)/ ) {
          # <link rev="made" href="mailto:Hanming.Tu@gmail.com"/>
          $rec =~ s/(href\=\"mailto):([\w\.\@]+)\"/$1:htu\@octagonresearch.com\"/;          
        } elsif ($rec =~ m/(content\=\"copyright)/ ) {
          # <meta name="copyright" content="copyright 2010 Hanming Tu" />
          $rec =~ s/(content\=\"copyright)\s*(\d+)\s*([\w ]+)\"/$1 $2 Octagon Research Solutions\"/;          
        }
        print OFN $rec; 
      }
      close OFN; 
      close IDX;
    }
  }
  
  # 7. tar and compress reports
  $s->echo_msg("7. tar and gzip reports", 2); 
  my $ad2 = "$adr/archived"; 
  if (!-d $ad2) { 
    $s->echo_msg("mkpath: $ad2", 3);      
    eval { mkpath($ad2) };
    $s->echo_msg("ERR: couldn't create $ad2: $@", 0) if ($@);
  } 
  my ($css_fn, $path, $sfx) = fileparse($css_style,qr{\..*});
  foreach my $k (sort keys %$r) {
    for my $i (0..$#{$r->{$k}}) {
      my $p   = $r->{$k}[$i]; 
      my $rd  = $p->{rdr};
      my $tm  = $p->{ptm}; 
      my $fn  = $p->{fn};
      my $sd  = $p->{sub};
      my $elp = time - $tm; 
      my $rt  = $fn; $rt =~ s/_index\.htm//; 
      my $sd2 = $sd; $sd2 =~ s/\/\w+$//; 
      my ($tf1,$tf2) = ("$ad2/$rt.tgz", "$adr/$sd2/$rt.tgz"); 
      $p->{dsp_tgz} = "$dsp_owb/$sn/$sd2/$rt.tgz";
      $p->{fn_tgz}  = "$rt.tgz"; 
      my ($tm1, $tm2) = (0,0); 
      $tm1 = (stat $tf1)[9] if -f $tf1; 
      $tm2 = (stat $tf2)[9] if -f $tf2; 
      if ($tm > $tm1 || $elp >= $rpt_kp) { 
        $s->echo_msg("INFO: reading $rd...", 2); 
        opendir RD, "$rd" || $s->echo_msg("WARN: could not opendir - $rd: $!", 0); 
        my @a = map {"$rdr/$_"; } sort grep !/\.bak$/, (grep /$rt/, readdir RD);
        closedir RD;
        $p->{old_fns} = [];
        for my $i (0..$#a) { $p->{old_fns}[$i] = $a[$i]; } 
      }
      # archived the original files
      if (!-f $tf1 || $tm > $tm1) {
        unlink $tf1 	if -f $tf1;
        my $fh1 = new IO::File "| /usr/bin/compress -c > $tf1";
        my $tar = Archive::Tar->new();
        $tar->setcwd($rd);
        $tar->add_files(@{$p->{old_fns}});
        $tar->write($fh1);
        $fh1->close ;      
      }
      # archived formated files
      if (!-f $tf2 || $tm > $tm2) {  
        unlink $tf2 	if -f $tf2;
        my $d2 = "$adr/$sd"; 
        opendir RD, "$d2" || $s->echo_msg("WARN: could not opendir - $d2: $!", 0); 
        my @b = map {"$d2/$_"; } sort grep !/\.bak$/, (grep /$rt/, readdir RD);
        closedir RD;
        my $fh2 = new IO::File "| /usr/bin/compress -c > $tf2";
        my $ta2 = Archive::Tar->new();
        $ta2->setcwd("$d2");
        $ta2->add_files(@b);
        $ta2->write($fh2);
        $fh2->close ;
      }
      if ($elp < $rpt_kp) {
        $s->echo_msg("INFO: $fn is still young.", 2);
        next;
      } else {
        $s->echo_msg("INFO: deleting $fn...", 2);
      } 
# $s->disp_param($p->{old_fns});       
      for my $i (0..$#{$p->{old_fns}}) {
        # we could not remove files from Window server right now
        my $f = $p->{old_fns}[$i]; 
        # print "RM: $f<br>\n"; 
      }
    }
  }  
  
  # 8. print the html
  $s->echo_msg("8. print html", 2);   
  if (! $rpt_cnt) {
    my $m = "ERR: no report from $rdr is found"; 
       $m .= " for Study $study_id." if $study_id; 
    $s->echo_msg($m, 0); 
    return; 
  }

  my $f_li = "  <li><b>%s - %s</b></li>\n";
  my $f_la = "  <li><a href='%s' target=R title='%s'>%s</a> (%s)</li>\n"; 
  my $f_aa = "  <a href='%s' target=R title='%s'>%s</a> (%s)\n"; 
  my $t = "<ul>\n"; 
  foreach my $k (sort keys %$r) {
    $t .= sprintf $f_li, $k, $sd->{$k}; 
    $t .= "  <ul>\n";
    for my $i (0..$#{$r->{$k}}) {
      my $p = $r->{$k}[$i]; 
      my $s1 = "$p->{fn_tgz} [created at $p->{ctm}]"; 
      my $s2 = "$p->{dsp_dir}\\$p->{fn}"; 
#      if (exists $p->{old_fns}) { 
        $t .= sprintf $f_la, $p->{dsp_tgz}, $p->{t}, $s1, $s2; 
#      } else {
#        $t .= "  <li> $s1 ($s2)";       
#      } 
    }
    $t .= "  </ul>\n"; 
  }
  $t .= "</ul>\n";
  print $t;
  return;
} 


=head2 disp_hids($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_hids {
  my ($s, $q, $ar) = @_;
  
  $s->disp_header($q,$ar,1);
  
  # 1. get variables
  my ($pid,$sn,$study_id,$study_name) = (); 
  $pid = $ar->{pid}		if exists $ar->{pid}; 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 

  # 2. check required elements
  if (!$pid) {
    $s->echo_msg("ERR: pid is not defined.", 0);  return; 
  }
  if (!$sn) {
    $s->echo_msg("ERR: server name is not defined.", 0);  return; 
  }
  if (!$study_id) {
    $s->echo_msg("ERR: study_id is not provided.", 0);  return; 
  }

  # 3. get a list of job ids
  my $jr = $s->get_jobid($ar); 
  my $jids = ""; 
  my $jhr = {}; 
  for my $i (0..$#$jr) { 
    $jids .= ($jids) ? ",$jr->[$i][0]" : $jr->[$i][0]; 
    $jhr->{$jr->[$i][0]} = $jr->[$i][1];
  }
  
  # 4. get a list of hist job ids
  my $whr  = "where job_id in ($jids)";
     $whr .= ' order by hjob_id'; 
  my $cns  = 'hjob_id,job_id,job_starttime,job_endtime,job_status';
  my $rr = $s->run_sqlcmd($ar,$cns,'cc_hist_jobs', $whr);
  my $hids = "";
  for my $i (0..$#$rr) { 
    $hids .= ($hids) ? ",$rr->[$i]{hjob_id}" : $rr->[$i]{hjob_id}; 
  }

  # 5. get finding count
  $whr = "where hjob_id in ($hids) group by hjob_id"; 
  $cns = "hjob_id,sum(count_invalid) as cnt_inv"; 
  my $r2 = $s->run_sqlcmd($ar,$cns,'cc_results', $whr);
  my $h2 = {};
  for my $i (0..$#$r2) { 
    $h2->{$r2->[$i]{hjob_id}} = $r2->[$i]{cnt_inv}; 
  }
  
  # 6. build html
  my $f_th  = "  <tr><th>%s\n      <th>%s\n      <th>%s\n";
     $f_th .= "      <th>%s\n      <th>%s\n      <th>%s\n  </tr>\n";
  my $f_tr  = "  <tr class=%s><td>%s\n      <td>%s\n      <td align=right>%s\n";
     $f_tr .= "      <td>%s\n      <td>%s\n      <td align=right>%s\n  </tr>\n";
  my $f_aa  = "  <a href='%s' title='%s' target=R>%s</a>\n"; 
  my $url   = $ar->{web_url};			# web URL
     $url  .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
  my $t = "<table>\n"; 
     $t .= "<caption>Hist Job List for Study $study_id";
     $t .= " - $study_name" 		if $study_name; 
     $t .= "</caption>\n"; 
     $t .= sprintf $f_th, "HJob ID", "Job Name", "Start Time", "End Time",
           "Status", "Finding Count"; 
  my @rec = (); 
  for my $i (0..$#$rr) {
    @rec = ();
    push @rec, (($i % 2 == 0) ? 'even' : 'odd'); 
    my $k = $rr->[$i]{hjob_id}; 
    my $v = $jhr->{$rr->[$i]{job_id}}; 
    my $u = "$url&task=sel_stat&sel_sn2=$k";
    push @rec, (sprintf $f_aa, $u, "Disp Stat (HJob_ID=$k)",$k); 
    push @rec, "$rr->[$i]{job_id} - $v"; 
    foreach my $j (split /,/,'job_starttime,job_endtime,job_status') {
      push @rec, ($rr->[$i]{$j}) ? $rr->[$i]{$j} : '&nbsp;';
    }
    push @rec, $h2->{$k}; 
    $t .= sprintf $f_tr, @rec; 
  }
  $t .= "</table>\n";

  # 6. print html
  
  if ($#$rr < 0) {
    my $m = "ERR: no table is found for Study $study_id - $study_name."; 
    $s->echo_msg($m, 0); 
    return; 
  }
  print $t;
  return;
} 


=head2 disp_tabs($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_tabs {
  my ($s, $q, $ar) = @_;

  print $s->disp_header($q, $ar);
  
  # 1. get variables
  my $prg = 'MapDisps::disp_tabs';
  $s->echo_msg("INFO: running $prg ...", 1);
  
  my ($sn,$odr,$rdr,$dsp,$study_id,$study_name,$tnm,$xnm) = (); 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name   = ''; 
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 
  $tnm  = ''; 
  $tnm	= uc($ar->{src_obj})		if exists $ar->{src_obj};
  $tnm	= uc($ar->{src_objects})	if !$tnm && exists $ar->{src_objects};
  $tnm  = uc($ar->{cpt_src_obj})	if !$tnm && exists $ar->{cpt_src_obj};
  $tnm	= '%FINAL'			if !$tnm; 
  $xnm  = '';
  $xnm	= uc($ar->{exl_objects})	if exists $ar->{exl_objects};
  $xnm	= uc($ar->{src_excl})		if exists $ar->{src_excl};
  $xnm  = uc($ar->{cpt_exl_obj})	if !$xnm && exists $ar->{cpt_exl_obj}; 

  # 2. check required elements
  if (!$sn) {
    $s->echo_msg("ERR: server name is not defined.", 0);  return; 
  }
  if (!$study_id) {
    $s->echo_msg("ERR: study_id is not provided.", 0);  return; 
  }

  # 3. get study schema and DBL

  my $whr = "where study_id = $study_id order by study_id"; 
  my $rr = $s->run_sqlcmd($ar,'src_schema,src_dbl','sp_studies', $whr);
  
  if ($#$rr < 0) {
    $s->echo_msg("ERR: could not find study_id - $study_id in study table.", 0); 
    return;
  }
  my $stg_sch = uc $rr->[0]{src_schema}; 
  my $stg_dbl = uc $rr->[0]{src_dbl};
  if (!$stg_sch && !$stg_dbl) {
    $s->echo_msg("ERR: could not find stg_schema($stg_sch) or stg_dbl($stg_dbl).",0); 
    return; 
  }
  # $s->echo_msg("INFO: STG_SCH=$stg_sch, STG_DBL=$stg_dbl", 3); 

  # 4. get all tables from staging schema and dbl link
  my $r = {}; 						# result array ref
  my ($wh1,$wh2,$r1,$r2) = ();

  # get number of rows for the tables  
  if ($stg_sch) {
    $wh1  = $s->cc_andwhere($stg_sch,  'owner', 'where'); 
    $wh1 .= $s->cc_andwhere($tnm, 'table_name', 'and'); 
    $wh1 .= $s->cc_andwhere($xnm, 'table_name', 'andnot'); 
    $r1   = $s->run_sqlcmd($ar,'table_name,num_rows','all_tables', $wh1);
    $wh2  = $s->cc_andwhere($stg_sch,      'owner', 'where'); 
    $wh2 .= $s->cc_andwhere('TABLE', 'object_type', 'and'); 
    $wh2 .= $s->cc_andwhere($tnm,    'object_name', 'and'); 
    $wh2 .= $s->cc_andwhere($xnm,    'object_name', 'andnot'); 
    $r2   = $s->run_sqlcmd($ar,'object_name,last_ddl_time','all_objects', $wh2);
    # $s->echo_msg("WH1=$wh1; WH2=$wh2",0);     
    for my $i (0..$#$r1) {
      my $k = $r1->[$i]{table_name}; 
      $r->{$k} = {}	if !exists $r->{$k}; 
      $r->{$k}{t_rows} = $r1->[$i]{num_rows}; 
    }
    for my $i (0..$#$r2) {
      my $k = $r2->[$i]{object_name}; 
      $r->{$k} = {}	if !exists $r->{$k}; 
      $r->{$k}{t_time} = $r2->[$i]{last_ddl_time}; 
    }
  }

  if ($stg_dbl) {
    $wh1  = $s->cc_andwhere($tnm, 'table_name', 'where'); 
    $wh1 .= $s->cc_andwhere($xnm, 'table_name', 'andnot'); 
    $r1   = $s->run_sqlcmd($ar,'table_name,num_rows',"user_tables\@$stg_dbl", $wh1);
    $wh2  = $s->cc_andwhere('TABLE', 'object_type', 'where'); 
    $wh2 .= $s->cc_andwhere($tnm, 'object_name', 'and');
    $wh2 .= $s->cc_andwhere($xnm,    'object_name', 'andnot');     
    $r2   = $s->run_sqlcmd($ar,'object_name,last_ddl_time',"user_objects\@$stg_dbl", $wh2);
    for my $i (0..$#$r1) {
      my $k = $r1->[$i]{table_name}; 
      $r->{$k} = {}	if !exists $r->{$k}; 
      $r->{$k}{s_rows} = $r1->[$i]{num_rows}; 
    }
    for my $i (0..$#$r2) {
      my $k = $r2->[$i]{object_name}; 
      $r->{$k} = {}	if !exists $r->{$k}; 
      $r->{$k}{s_time} = $r2->[$i]{last_ddl_time}; 
    }
  }

  # 5. build html
  my $f_th  = "  <tr><th>%s\n      <th>%s\n      <th>%s\n";
     $f_th .= "      <th>%s\n      <th>%s\n  </tr>\n";
  my $f_tr  = "  <tr class=%s><td>%s\n      <td>%s\n      <td align=right>%s\n";
     $f_tr .= "      <td>%s\n      <td align=right>%s\n  </tr>\n";
  my $rec_cnt = 0; 
  my $t = "<table>\n"; 
     $t .= "<caption>Table comparison Between Source ";
     $t .= "and Staging Schemas ";
     $t .= "for Study $study_id - $study_name<br>($tnm;$xnm)</caption>\n"; 
     $t .= "  <tr><th><th colspan=2>Source: $stg_dbl\n";
     $t .= "  <th colspan=2>Target: $stg_sch</tr>\n";     
     $t .= sprintf $f_th, "Table Name", "DDL Time", "Num of Rows",
           "DDL Time", "Num of Rows"; 
  my @rec = (); 
  foreach my $k (sort keys %$r) {
    $rec_cnt += 1; 
    my @rec = ();
    push @rec, (($rec_cnt % 2 == 0) ? 'even' : 'odd'); 
    push @rec, $k; 
    foreach my $j (split /,/,'s_time,s_rows,t_time,t_rows') {
      push @rec,((!exists $r->{$k}{$j}) ? '<b>N/A</b>' : 
        (($r->{$k}{$j})?$r->{$k}{$j}:'&nbsp;'));
    } 
    $t .= sprintf $f_tr, @rec; 
  }
  $t .= "</table>\n";
  $t .= "<b>Total $rec_cnt records.</b>\n";

  # 6. print html
  
  if (! $rec_cnt) {
    my $m = "ERR: no table is found for Study $study_id ($stg_sch.$tnm)."; 
    $s->echo_msg($m, 0); 
    return; 
  }
  print $t;
  return;
} 


=head2 disp_rpts($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_rpts {
  my ($s, $q, $ar) = @_;
  
  $s->disp_header($q,$ar,1);
  
  # 1. get variables
  my ($sn,$odr,$rdr,$dsp,$study_id,$study_name) = (); 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $odr = eval $s->set_param('out_dir', $ar); 		# output dir
  $rdr = $odr->{$sn}{rpt};  				# rpt dir
  $dsp = $odr->{$sn}{dsp};				# dsp url
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 

  $s->echo_msg("INFO: RDR - $rdr<br>\nDSP - $dsp",3);

  # 2. check required elements
  if (! -d $rdr) {
    $s->echo_msg("ERR: could not find rpt dir - $rdr.", 0);  return; 
  }

  # 3. get study id
  my $studyid = $s->get_studyid($ar); 			# study ids
  my $sd = {};						# study id hash array
  for my $i (0..$#$studyid) { 
    $sd->{$studyid->[$i][0]} = $studyid->[$i][1];
  }

  # 4. get all index files  
  my $fname = 'index';
  opendir DD, "$rdr" or die "ERR: could not opendir - $rdr: $!\n";
  my @a = sort grep !/\.bak$/, (grep /$fname/, readdir DD);
  closedir DD;

  # 5. loop through each file
  my $r = {}; 						# result array ref
  my $rpt_cnt = 0;
  for my $i (0..$#a) {
    my ($sid, $jid, $hid, $hms) = ($a[$i] =~ m/rpt(\d+)_(\d+)_(\d+)_(\d+)/); 
    next if $study_id && $study_id != $sid; 
    $rpt_cnt += 1; 
    my @b = stat "$rdr/$a[$i]"; 
    my $ctm = strftime "%Y/%m/%d %H:%M:%S", localtime($b[9]);
    my $tit = sprintf "S%03dJ%04dH%05d", $sid, $jid, $hid;
    $r->{$sid} = [] if !exists $r->{$sid}; 
    push @{$r->{$sid}}, {dsp=>"$dsp/$a[$i]",ctm=>$ctm,fn=>$a[$i],t=>$tit};
    # print "$a[$i] - $sid:$jid:$hid:$hms:$ctm<br>\n"; 
  }
  
  # 6. print the html
  if (! $rpt_cnt) {
    my $m = "ERR: no report is found"; 
       $m .= " for Study $study_id." if $study_id; 
    $s->echo_msg($m, 0); 
    return; 
  }

  my $f_li = "  <li><b>%s - %s</b></li>\n";
  my $f_la = "  <li><a href='%s' target=R title='%s'>%s</a> (%s)</li>\n"; 
  my $t = "<ul>\n"; 
  foreach my $k (sort keys %$r) {
    $t .= sprintf $f_li, $k, $sd->{$k}; 
    $t .= "  <ul>\n";
    for my $i (0..$#{$r->{$k}}) {
      my $p = $r->{$k}[$i]; 
      $t .= sprintf $f_la, $p->{dsp}, $p->{t}, $p->{fn}, "created at $p->{ctm}"; 
    }
    $t .= "  </ul>\n"; 
  }
  $t .= "</ul>\n";
  print $t;
  return;
} 


=head2 disp_client($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_client {
  my ($s, $q, $ar) = @_;

  $s->disp_header($q,$ar,1);

  my $whr = ' WHERE  client_status = 1 ';
    $whr .= ' ORDER BY client_id';  
  my $r = $s->run_sqlcmd($ar, 'client_id,client_name', 'sp_clients', $whr);   
  print   $s->build_links($r, $ar);     
  return;
} 

=head2 disp_project($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_project {
  my ($s, $q, $ar) = @_;
  
  $s->disp_header($q,$ar,1);
  
  my $whr = " WHERE prj_status = 1";
    $whr .= " AND client_id=$ar->{cln_id} ORDER BY prj_id " 
    if exists $ar->{cln_id} && $ar->{cln_id};
  my $r = $s->run_sqlcmd($ar, 'prj_id,prj_name', 'sp_projects', $whr);   
  print   $s->build_links($r, $ar);     
  return;
} 

=head2 disp_study($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_study {
  my ($s, $q, $ar) = @_;
  
  $s->disp_header($q,$ar,1);
  
  my $whr = " WHERE study_status = 1";
  $whr .= " AND prj_id=$ar->{prj_id}" if exists $ar->{prj_id} && $ar->{prj_id};
  $whr .= ' ORDER BY study_id ';
  my $r = $s->run_sqlcmd($ar, 'study_id,study_name', 'sp_studies', $whr);   
  print   $s->build_links($r, $ar);     
  return;
} 

=head2 disp_list($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_list {
  my ($s, $q, $ar) = @_;

  $s->disp_header($q,$ar,1);
  
  my $whr = "WHERE sp_status = 1 ";
    $whr .= "  AND study_id=$ar->{study_id}" 
    if exists $ar->{study_id} && $ar->{study_id};
  $whr .= " ORDER BY list_id"; 
  my $r = $s->run_sqlcmd($ar, 'list_id,sp_source,sp_version', 'sp_lists', $whr);  
  for my $i (0..$#$r) {
    # my @a = split /[\/|\/]/, $r->[$i]{sp_source}; 
    # $r->[$i]{sp_source} = $a[$#a]; 
    my $v = $r->[$i]{sp_source};
    if ($v =~ /[\\\/]([\w\.]+)$/) {
       $r->[$i]{sp_source} = $1; 
    } 
  }
  print   $s->build_links($r, $ar);     
  return;
} 

=head2 disp_job($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History:
  08/28/2013 (htu): sorted job_id descendingly. 

=cut

sub disp_job {
  my ($s, $q, $ar) = @_;

  $s->disp_header($q,$ar,1);
  
  my $sql = "ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';\n";
  $sql .= "SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;\n";
  $sql .= "SELECT '==,'||job_id||',<b>'||job_type||'</b>; '||job_starttime";
  $sql .= "||'; <b>'||job_status||'</b>; '||job_args as record ";
  $sql .= "FROM sp_jobs WHERE 1=1 ";
#  $sql .= " AND (upper(job_status) like 'COMP%' "; 
#  $sql .= "OR upper(job_status) like 'RUN%') ";
  if (exists $ar->{list_id} && $ar->{list_id}) {
    $sql .= " AND list_id = $ar->{list_id} ORDER BY job_id desc; \n";
  } else {
    $sql .= ";\n"; 
  }  
  my $rst  = $s->open_cmd($sql,$ar); 
  my $vr = ['job_id','job_type','job_starttime','job_status','job_args']; 
  $ar->{var_arf} = $vr; 
  my $rr  = $s->parse_records($rst, $vr, '==', ','); 

  for my $i (0..$#$rr) {
    next if exists $rr->[$i]{job_action} && ! $rr->[$i]{job_action}; 
    $rr->[$i]{job_action} =~ s/\#/,/g if exists $rr->[$i]{job_action}; 
  }
  
  # $s->disp_param($rr); 
 
  print $s->build_links($rr, $ar);     
  return;
} 


=head2 disp_logfiles($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_logfiles {
  my ($s, $q, $ar) = @_;

  $s->disp_header($q,$ar,1);
  
  my $prg = 'CGI::AppBuilder::MapDisps->disp_logfiles';
  my $sql = "ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';\n";
  $sql .= "SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;\n";
  $sql .= "SELECT '==,'||job_id||','||job_starttime||','||job_status||','";
  $sql .= "||job_type||','||job_outpath as record ";
  $sql .= " FROM sp_jobs WHERE 1=1 ";
  $sql .= "  AND job_id = $ar->{job_id} " 	if exists $ar->{job_id};
  $sql .= "  AND list_id = $ar->{list_id} " 	if exists $ar->{list_id};
  $sql .= " ORDER BY job_id DESC; \n";  
  
  my $rst  = $s->open_cmd($sql,$ar); 
  my $vr = ['job_id','job_starttime','job_status','job_type','job_outpath']; 
  $ar->{var_arf} = $vr; 
  my $rr  = $s->parse_records($rst, $vr, '==', ','); 
  my $ds = (exists $ar->{dir_sep}) ? $ar->{dir_sep} : '/'; 

  # $s->disp_param($rr);

  my $t = "<ul>\n";
  $t .= '<font color=red>OK</font><br>' ;
  if (!@$rr) { 
    $t .= "<font color=red>No log for ";
    $t .= " job_id = $ar->{job_id}"	if exists $ar->{job_id} ;
    $t .= " list_id = $ar->{list_id}"	if exists $ar->{list_id} ;
    $t .= "</font><br>\n"; 
  } 
  for my $i (0..$#$rr) {
    my $dir = $rr->[$i]{job_outpath};  $dir =~ s/^\s*//g; $dir =~ s/\s*$//g; 
    my $jid = $rr->[$i]{job_id}; 
    my $stm = $rr->[$i]{job_starttime}; 
    my $sta = $rr->[$i]{job_status}; 
    my $typ = $rr->[$i]{job_type};
    next if $dir =~ /^\s*$/; 
    my @aa = (); 
    if (-f $dir || $dir =~ /\.(sql|txt|sas)$/) {
      push @aa, $dir; 
      my ($txf) = ($dir =~ /(.+)\.sql$/);
         $txf = "$txf.txt";
      push @aa, $txf if (-f $txf); 
    } elsif (-d $dir || $dir =~ /^\\\\/) {
      opendir DD, "$dir" or $s->echo_msg("ERR: ($prg) Could not open dir - $dir for job_id=$jid: $!",0);
      @aa = sort grep /^$jid/, readdir DD;
      closedir DD;
      for my $i (0..$#aa) { $aa[$i] = join $ds, $dir, $aa[$i]; } 
    } else { 
      $s->echo_msg("WARN: ($prg) could not find dir or file - $dir.",1);
      # next;
    }
    $t .= "  <li> $jid - <a href='#' title='$dir'>$stm: $typ $sta</a>\n"; 
    $t .= $s->disp_linkedfiles(undef, $ar, \@aa, 1) if @aa; 
  }
  $t .= "</ul>\n"; 
  print $t;   
 
  # print $s->build_links($rr, $ar);     
  return;
} 


=head2 build_links($q,$pr,$ar)

Input variables:

  $pr	- array ref containing id and name 
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub build_links {
  my ($s, $pr, $ar) = @_;
  
  # 0 - return if $pr is empty
  if (!$pr || $#$pr < 0) {
    $s->echo_msg("WARN: No records.",0); return; 
  }

  # 1. define variables
  my $vs = 'pid,sid,guid,web_url,task';
  my ($pid,$sid,$usr_gid,$url,$tsk) = $s->get_params($vs,$ar); 
     $sid = $ar->{sel_sn1}		if !$sid && exists $ar->{sel_sn1}; 
  my $tgt = (exists $ar->{fr_tgt}) ? $ar->{fr_tgt} : "R";	# frame target

  my $tk = $tsk; $tk =~ s/(disp_)//;  
  my $tr = {'client'=>'project','project'=>'study','study'=>'list','list'=>'job' };
  my $br = {'client'=>'','project'=>'cln','study'=>'prj','list'=>'study'
           ,'job'=>'list' };
  my $tg = {'client'=>'D2','project'=>'D3','study'=>'D4','list'=>'R' };
  my $id = {'client'=>'cln_id','project'=>'prj_id','study'=>'study_id'
           ,'list'=>'list_id','spec'=>'spec_id', 'job'=>'job_id' };
  my $nm = {'client'=>'cln_name','project'=>'prj_name','study'=>'study_name'
           ,'list'=>'sponsor','spec'=>'source_dataset', 'job'=>'job_name' };

  $url =~ s/(\?.*)//    	if $url;	# remove parameters
  $url .= "?pid=$pid&sel_sn1=$sid&guid=$usr_gid"; 
    
  # 2. check required variables 
  if (!$pid) {
    $s->echo_msg("ERR: could not find pid in build_links.",0); return;
  }
  if (!$sid) {
    $s->echo_msg("ERR: could not find sid in build_links.",0); return;
  }

  # 3. build links
  my $f_aa = "  <a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n"; 
  my $f_bb = "<b>%s</b>\n";
  my $f_li = "  <li>%s</li>\n";
  my $ttk  = (exists $tr->{$tk} && $tr->{$tk}) ? $tr->{$tk} : ""; 

  my $vr   = $ar->{var_arf};   
  my $u_lf = "$url&task=disp_map_task";
  my $u_rt = "$url&task=disp_$ttk"; 
  my $u_ct = "$url&task=disp_new&new_task=add_$ttk"; 
#  my $ids  = 'cln_id,prj_id,study_id,job_id,hjob_id'; 
  my $cnt_ar = {}; 
  foreach my $kk (keys %$id) {
    my $k = $id->{$kk}; 
    my $n = $nm->{$kk}; 
    if (exists $ar->{$k} && $ar->{$k}) { 
      $u_lf .= "&$k=$ar->{$k}";
      $u_rt .= "&$k=$ar->{$k}"; 
      $u_ct .= "&$k=$ar->{$k}"; 
    }
    if (exists $ar->{$n} && $ar->{$n}) { 
        $u_lf .= "&$n=$ar->{$n}";
        $u_rt .= "&$n=$ar->{$n}"; 
        $u_ct .= "&$n=$ar->{$n}"; 
    }
#      $cnt_ar->{$n} += 1; 
  }
  my $q = CGI->new; 
  my $t  = $s->disp_header($q,$ar); 
     $t .= "<center>" . (sprintf $f_bb, uc($tk)) . ': ';
#     $t = sprintf $f_aa, "$url&task=disp_new&new_task=add_$tk", 'R', "Add $tk", $t; 
#     $t .= "<ul>\n"; 
  my $v_id = $vr->[0];
  my $v_nm = $vr->[1]; 

  my $k1 = $br->{$tk} . '_id'; 
  my $n1 = $br->{$tk} . '_name'; 
  my $kn = (exists $ar->{$n1}) ? "$ar->{$k1} - $ar->{$n1}" : "Add $tk"; 
  my $u1 = "$url&task=disp_new&new_task=add_$tk&$k1=$ar->{$k1}"; 
  $t .=  (sprintf $f_aa, $u1 ,"R","Add $tk",$kn) . "</center>";
  $t .= "<br>\n"; 

# $s->disp_param($pr);
# print "VID=$v_id, VNM=$v_nm<br>\n";   

  for my $i (0..$#$pr) {
    next if ref($pr->[$i]) !~ /^HASH/;   
    my $k  = $pr->[$i]{$v_id}; 
    my $v  = $pr->[$i]{$v_nm}; 
    my $uk = "$id->{$tk}=$k"; 
    my $un = "$nm->{$tk}=$v";
    my $lf = "$u_lf&$uk&$un";
    my $rt = "$u_rt&$uk&$un"; 
    my $ct = "$u_ct&$uk&$un"; 
    my $t1  = "[\n" . sprintf $f_aa, $lf, 'L', "Set", "&lt;"; 
    if (exists $tr->{$tk}) {
       $t1 .= sprintf $f_aa, $ct, 'R', "Add $tr->{$tk} to $tk $k", '+'; 
       $t1 .= sprintf $f_aa, $rt, $tg->{$tk}, "expand to $tr->{$tk}", "&gt;";
    } else {
      # http://ors2di/cgi/jp2.pl?pid=ckpt&no_dispform=1&sel_sn1=vpapp2&sel_sn2=1261&task=sel_stat    
       my $u = "$url&no_dispform=1&task=sel_stat&sel_sn2=$k";
       $t1 .= sprintf $f_aa, $u, 'R', "Show Stat for Job - $k", 'S'; 
    }
       $t1 .= "]\n"; 
       $t1 .= sprintf "%3d - %s<br>\n", $k, $v;
#    $t .= sprintf $f_li, $t1; 
     $t .= $t1;
  }
#  $t .= "</ul>\n"; 
  
 return $t; 

}


=head2 disp_links($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_links {
  my ($s, $q, $ar) = @_;
  
  print $s->disp_header($q,$ar);
  
  my $ovs = eval $s->set_param('opf_values', $ar);
  my $ols = eval $s->set_param('opf_labels', $ar);
  # my $utk = eval $s->set_param('act_user',$ar); 
  # my $utk = eval $s->set_param('act_admin',$ar);
  my $avl = eval $s->set_param('act_values',$ar); 
  my $alb = eval $s->set_param('act_labels',$ar); 

  my $f_li = "  <li><a href=\"%s\" target=R>%s</a></li>\n";
  my $f_bb = "<b>%s</b>\n";

#  my $pr  = $s->def_inputvars($ar);
  my $sn  = $ar->{sid}; 				# server id
  my $url = $ar->{web_url};   				# web URL
     $url =~ s/(\?.*)// if $url;			# remove parameters
     $url .= "?pid=$ar->{pid}";
     $url .= "&sel_sn1=$sn"		if $sn; 
  my ($study_id) = ();
  $study_id = $ar->{study_id} if exists $ar->{study_id} && !$ar->{study_id}; 
  $url .= "&study_id=$study_id"		if $study_id; 

  my $t = ""; 
  for my $i (0..$#$avl) { 
    my $k = $avl->[$i];
    my $v = $alb->{$k};
    next if $k =~ /^0$/; 
    if ($k =~ /^\d/) {
      if ($k !~ /^0$/) {
        $t .= "</ul>\n";
        $v =~ s/_//g; 
        $t .= sprintf $f_bb, "$k - $v";     
      } 
      next; 
    } 
    $t .= sprintf $f_li, "$url&task=$k&a=help", $v  
  }
  $s->disp_task_form($q,$ar,$t); 
  print $s->disp_footer($q,$ar);
  
  return;
} 

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from jp2.pl on 09/08/2010.

=item * Version 0.20

  09/08/2010 (htu): start this PM
  02/16/2012 (htu): started using set_ids in disp_map_task
  
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

