package CGI::AppBuilder::TaskDisps;

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
use File::Copy;
use File::Basename;
use Archive::Tar; 
use IO::File;
use Net::Rexec 'rexec';

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(disp_links  build_links cc_andwhere
                   disp_client disp_project disp_study disp_job disp_hjob 
                   disp_cptable disp_rpts disp_tabs disp_hids disp_archive
                   test_dbl check_droptabs check_chkids disp_htmlrpt
                   );
our %EXPORT_TAGS = (
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::TaskDisps - Display tasks

=head1 SYNOPSIS

  use CGI::AppBuilder::TaskDisps;

  my $sec = CGI::AppBuilder::TaskDisps->new();
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

=head2 check_chkids($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History: 

=cut

sub check_chkids {
  my ($s, $q, $ar) = @_;
  
  my $prg = 'CGI::AppBuilder::TaskDisps->check_chkids';
  # 1. get variables
  my ($sn,$dbl,$dbl_vars, $study_id,$study_name,$tnm,$xnm) = (); 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 
  my $id = 'rule_version'; 
  my $r_vsn = (exists $ar->{$id} && $ar->{$id}) ? $ar->{$id} : ''; 
     $id = 'sel_list'; 
  my $r_dmn = (exists $ar->{$id} && $ar->{$id}) ? $ar->{$id} : ''; 
     $id = 'sel_rid'; 
  my $r_rid = (exists $ar->{$id} && $ar->{$id}) ? $ar->{$id} : ''; 
     $id = 'exl_list'; 
  my $r_exl = (exists $ar->{$id} && $ar->{$id}) ? $ar->{$id} : ''; 

  # 2. check required elements
  if (!$sn) {
    $s->echo_msg("ERR: ($prg) server name is not defined.", 0);  return; 
  }
  if ($study_id != 0 && !$study_id) {
    $s->echo_msg("ERR: ($prg) study_id is not provided.", 0);  return; 
  }

  # 3. build where clause and SQL statements

  my $wh1 = "WHERE upper(rule_status) = 'ACTIVE' ";
    $wh1 .= '  AND (effective_date  is null OR sysdate > effective_date) ';
    $wh1 .= '  AND (expiration_date is null OR sysdate < expiration_date) '; 
    $wh1 .= $s->cc_andwhere($r_vsn, 'rule_version', 'and');
    $wh1 .= $s->cc_andwhere($r_dmn, 'rule_domain', 'and');
    $wh1 .= $s->cc_andwhere($r_rid, 'rule_id', 'and');
    $wh1 .= $s->cc_andwhere($r_exl, 'rule_domain', 'andnot');
  my $s1 = "SELECT rule_uid FROM cc_rules\n $wh1\n";    
  my $wh2 = " WHERE rule_uid IN ($s1)\n";
    $wh2 .= "   AND cc_status = 'A' \n";
    $wh2 .= "   AND (cc_effective_date  is null OR sysdate > cc_effective_date)\n";
    $wh2 .= "   AND (cc_expiration_date is null OR sysdate < cc_expiration_date)\n";
  my $s2 = "SELECT chk_id FROM cc_checks\n $wh2\n";

  my $c1 = "rule_id,rule_domain,rule_version,severity,rule_description";
  my $r1 = $s->run_sqlcmd($ar,$c1,'cc_rules', $wh1, 1);
  my $rec_cnt = $#$r1 + 1; 

  my $m = "($r_vsn:$r_dmn:$r_rid:$r_exl)";
  if (! $rec_cnt) {
    $m = "ERR: ($prg) no rule id is found for Study $study_id $m."; 
    $s->echo_msg($m, 0); 
    return; 
  }
  
  my $c2 = "chk_id";
  my $r2 = $s->run_sqlcmd($ar,$c2,'cc_checks',$wh2); 
  my $chk_ids = '';
  for my $i (0..$#$r2) { 
    $chk_ids .= ($chk_ids) ? "," : '';
    $chk_ids .= $r2->[$i]{chk_id};
  }

  $s->echo_msg("SQL: $s1", 3); 
  $s->echo_msg("SQL: $s2", 3); 

  # 4. build html
  my $t  = "<table>\n"; 
     $t .= "<caption>Rule List In Study ";
     $t .= (defined $study_id)   ? "$study_id - "   : ' - ';
     $t .= (defined $study_name) ? "$study_name $m" : " $m";
     $t .= "</caption>\n"; 
  my $t1 = "<tr>\n";
  my $f_tr = "<tr class=%s>\n"; 
  my $c_cnt = 0; 
  for my $k (split /,/,$c1) { 
    ++$c_cnt; 
    $t1   .= "  <th>" . ucfirst($k) . "</th>\n"; 
    $f_tr .= "  <td>%s</td>\n";
  }
  $t1   .= "</tr>\n"; 
  $f_tr .= "</tr>\n"; 
     $t .= $t1; 
  for my $i (0..$#$r1) {
    my   @rec = (); 
    push @rec, (($i % 2 == 0) ? 'even' : 'odd'); 
    for my $k (split /,/,$c1) { 
      my $v = $r1->[$i]{$k}; 
      push @rec, ($v !~ /^\s*$/) ? $v : '&nbsp;'; 
    } 
    $t .= sprintf $f_tr, @rec; 
  }
  $t .= "<tr><td colspan=$c_cnt>";
  $t .= "<b>Total $rec_cnt records: </b>$chk_ids</td>\n</tr>\n";
  $t .= "</table>\n";
  
  # 5. print html

  print $t;
  return;
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
  
  my $prg = 'CGI::AppBuilder::TaskDisps->check_droptabs';
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
  $tnm	= '%FINAL'			if !$tnm; 
  my $exc_vars = (exists $ar->{exc_vars}) ? $ar->{exc_vars} : ''; 
  if ($exc_vars) { 
    for my $k (split /,/, $exc_vars) {
       $xnm = uc($ar->{$k})	if !$xnm && exists $ar->{$k}; 
    } 
  } 

  # 2. check required elements
  if (!$sn) {
    $s->echo_msg("ERR: server name is not defined.", 0);  return; 
  }
  if ($study_id != 0 && !$study_id) {
    $s->echo_msg("ERR: study_id is not provided.", 0);  return; 
  }

  # 3. get study schema and DBL

  my $whr = "where study_id = $study_id order by study_id"; 
  my $rr = $s->run_sqlcmd($ar,'study_name,stg_schema,stg_dbl','cc_studies', $whr);
  
  if ($#$rr < 0) {
    $s->echo_msg("ERR: could not find study_id - $study_id in study table.", 0); 
    return;
  }
  $study_name = $rr->[0]{study_name}	if !$study_name;
  my $stg_sch = uc $rr->[0]{stg_schema}; 
  my $stg_dbl = uc $rr->[0]{stg_dbl};
  if (!$stg_sch ) {
    $s->echo_msg("ERR: could not find stg_schema($stg_sch).",0); 
    return; 
  }
  $s->echo_msg("INFO: STG_SCH=$stg_sch, STG_DBL=$stg_dbl", 3); 

  # 4. get all tables from staging schema
  my $r = {}; 						# result array ref
  my ($wh1,$wh2,$r1,$r2) = ();

  # get number of rows for the tables  
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

  # 5. build html
  my $f_th  = "  <tr><th>%s\n      <th>%s\n      <th>%s\n  </tr>\n";
  my $f_tr  = "  <tr class=%s><td>%s\n      <td>%s\n      ";
     $f_tr .= "<td align=right>%s\n  </tr>\n";
  my $rec_cnt = 0; 
  my $t  = "<font color=red>The following tables will be dropped if you click ";
     $t .= "the <b>Go</b> button:</font> <br><br>\n"; 
     $t .= "<table>\n"; 
     $t .= "<caption>Tables In Study $study_id - $study_name<br>";
     $t .= "($stg_sch;$tnm;$xnm)</caption>\n"; 
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
    my $m = "ERR: no table is found for Study $study_id ($tnm)."; 
    $s->echo_msg($m, 0); 
    return; 
  }
  print $t;
  return;
} 


=head2 test_dbl($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

History: 

=cut

sub test_dbl {
  my ($s, $q, $ar) = @_;
  
  my $prg = 'CGI::AppBuilder::TaskDisps->test_dbl';
  # 1. get variables
  my ($sn,$dbl,$dbl_vars, $study_id,$study_name) = (); 
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $study_id 	= $ar->{study_id}	if exists $ar->{study_id};
  $study_name	= $ar->{study_name}	if exists $ar->{study_name}; 
  $dbl_vars	= $ar->{dbl_vars}	if exists $ar->{dbl_vars};
  if ($dbl_vars) {
    foreach my $k (split /,/, $dbl_vars) {
      $dbl = $ar->{$k}	if exists $ar->{$k} && $ar->{$k}; 
    }
  }
  $s->echo_msg("INFO: ($prg) DBL: $dbl",3);

  # 2. check required elements
  if (!$dbl) {
    $s->echo_msg("ERR: ($prg) no DB Link is specified.", 1); 
    $s->echo_msg("Please select a Source DBL.", 1); 
    return; 
  }
  my $pid = $ar->{pid}; 			# project id: ckpt, dba, owb			
  my $url = $ar->{web_url};			# web URL
    $url .= "?pid=$pid&no_dispform=1&task=run_dropdbl&sel_sn1=$sn";
    $url .= "&sel_sn2=$dbl"; 

  # 3. get db link 
  my $whr  = "";
  my $cns  = 'sysdate as sys_dtm';
  my $rr = $s->run_sqlcmd($ar,$cns,"dual\@$dbl", $whr);
  my $dbl_flag = 1;

  my $msg = '';
  if (! exists $rr->[0]{sys_dtm}) {
    $msg = "ERR: DBL - $dbl is not valid. ";
    $dbl_flag = 0; 
  } else {
    $msg = "INFO: DBL - $dbl is valid and got DTM ($rr->[0]{sys_dtm})";
  } 
  $s->echo_msg($msg, 0);   
  
  # 4. get a list of DBL
  $whr  = "where UPPER(db_link) like UPPER('$dbl%')";
  $cns  = 'owner,db_link,username,host,created';
  $rr = $s->run_sqlcmd($ar,$cns,"dba_db_links", $whr);
  my $cn = [split /,/, $cns]; 

  # 5. build html
  my $f_th  = "    <th>%s</th>\n"; 
  my $f_td  = "    <td>%s</td>\n"; 
  my $f_tr  = "  <tr>\n%s</tr>\n"; 
  my ($t, $t1) = (); 
  my $rec_cnt = 0; 
  $t = "<p><p>\n<table border=1>\n"; 
  $t .= "<caption>Table DB Link Detail for $dbl</caption>\n"; 
  for my $i (0..$#$cn) {
    $t1 .= sprintf $f_th, ucfirst($cn->[$i]); 
  } 
  $t .= sprintf $f_tr, $t1; 
  $rec_cnt = $#$rr + 1; 
  for my $i (0..$#$rr) {
    $t1 = ''; 
    for my $j (0..$#$cn) {
      my $k = $cn->[$j]; 
      $t1 .= sprintf $f_td, $rr->[$i]{$k}; 
    } 
    $t .= sprintf $f_tr, $t1; 
  }
  $t .= "</table>\n";
  $t .= "<b>Total $rec_cnt records.</b>\n";
  
  # 6. print html
  
  if (! $rec_cnt) {
    my $m = "ERR: no record found for DBL $dbl."; 
    $s->echo_msg($m, 0); 
    return; 
  } else {
    if (! $dbl_flag) {
      $msg = "You can remove this invalid DBL by click ";
      $msg .= "<a href='$url'>Remove $dbl</a>.";
      $s->echo_msg($msg, 0); 
    }
  }
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
  
  my $prg = "AppBuilder::TaskDisps->disp_archive";
  # 1. get variables
  $s->echo_msg("1. get variables", 2); 

  my $pid = (exists $ar->{pid}) ? $ar->{pid} : '';  
  my $sn  = (exists $ar->{sid}) ? $ar->{sid} : ''; 
     $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
     $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  my $ds  = (exists $ar->{dir_sep}) ? $ar->{dir_sep} : '';
     $ds  = ($^O =~ /^MSWin/i) ? '\\' : '/' 	if ! $ds; 
  my $adr = (exists $ar->{arch_dir}) ? (join $ds, $ar->{arch_dir}, $sn) : ''; 
  my $odr = eval $s->set_param('out_dir', $ar); 		# output dir
  my $rdr = (exists $odr->{$sn}{rpt})  ? $odr->{$sn}{rpt} : ''; # rpt dir
  my $dsp = (exists $odr->{$sn}{dsp})  ? $odr->{$sn}{dsp} : '';	# dsp url
     $dsp = (exists $ar->{script_url}) ? $ar->{script_url} :'' if !$dsp;
  $s->echo_msg("WARN: ($prg) DSP URL is not defined.", 1) if ! $dsp; 
     $dsp .= '?' . "pid=$pid&target=$sn&task=disp_file&f=";

  my $css_style = (exists $ar->{css_style}) ? $ar->{css_style} : '';
  my $dsp_owb   = (exists $ar->{dsp_owb})   ? $ar->{dsp_owb}   : '';
  my $dsp_dir   = (exists $ar->{dsp_dir})   ? $ar->{dsp_dir}   : '';
  my $rpt_kp    = (exists $ar->{rpt_keep})  ? $ar->{rpt_keep}  : ''; # seconds 

#  my ($jid,$hid) = (); 
  my $study_id 	= (exists $ar->{study_id})  ? $ar->{study_id}  : '';
  my $study_name= (exists $ar->{study_name})? $ar->{study_name}: '';
  my $job_id 	= (exists $ar->{job_id})    ? $ar->{job_id}    : ''; 
  my $hjob_id 	= (exists $ar->{hjob_id})   ? $ar->{hjob_id}   : ''; 

  $s->echo_msg("INFO: ($prg) RDR - $rdr<br>\nDSP - $dsp",3);

  # 2. check required elements
  $s->echo_msg("2. check required variables", 2); 
  if (! -d $ar->{arch_dir}) {
    $s->echo_msg("ERR: ($prg) could not find archive dir - $ar->{arch_dir}.", 0);
    return; 
  }
  $s->echo_msg("INFO: mkpath - $adr", 2);      
  eval { mkpath($adr) };
  $s->echo_msg("ERR: ($prg) couldn't create $adr: $@", 0) if ($@);

  if (! -d $rdr) {
    $s->echo_msg("ERR: ($prg) could not find rpt dir - $rdr.", 0);  return; 
  }
  
  if (! -f $css_style) {
    $s->echo_msg("WARN: ($prg) could not find css style file - $css_style.", 1);
  }

  # 3. get study id 
  $s->echo_msg("3. get study id and name", 2); 
  my $studyid = $s->get_studyid($ar); 			# study ids
  my $sd = {};						# study id hash array
  for my $i (0..$#$studyid) { 
    $sd->{$studyid->[$i][0]} = $studyid->[$i][1];
  }
  $s->echo_msg($sd, 3);

  # 4. get all index files  
  $s->echo_msg("4. get all index files", 2); 
#  my $fname = 'index';
#  opendir DD, "$rdr" or die "ERR: could not opendir - $rdr: $!\n";
#  my @a = sort grep !/\.bak$/, (grep /$fname/, readdir DD);
#  closedir DD;
  $ar->{job_id} = '';		# remove job_id to use study_id to get_htmlrpts
  my $rr = $s->get_htmlrpts($ar); 
  $ar->{job_id} = $job_id; 
  $s->echo_msg($rr, 3);   
  my @a = (); 
  for my $i (0..$#$rr) {
    $a[$i] = $rr->[$i]{stat}{fn}; 
  }
  $s->echo_msg("INFO: Found " . ($#a+1) . " index files", 3);   

  # 5. loop through each file
  $s->echo_msg("5. build index file array", 2); 
  my $r = {}; 						# result array ref
  my $rpt_cnt = 0;
  my @b = ();
  my ($ctm, $tit,$sub, $sb2) = ();
  my $dft = "%Y/%m/%d %H:%M:%S"; 
  for my $i (0..$#a) {
    my ($fn) = ($a[$i] =~ m/(rpt\d+_\d+_\d+_\d+_\w+\.\w+)/); 
    my $f2   = $rr->[$i]{fn2};				# report file name
    $s->echo_msg("processing $f2 ($fn)...", 3); 
    my ($sid, $jid, $hid, $hms) = ($fn =~ m/rpt(\d+)_(\d+)_(\d+)_(\d+)/); 
    next if ($study_id =~ /^\d+$/) && $study_id != $sid; 
    next if ($job_id   =~ /^\d+$/) && $job_id   != $jid; 
    next if ($hjob_id  =~ /^\d+$/) && $hjob_id  != $hid; 
    if (-f $f2) {
      $rpt_cnt += 1; 
      @b = stat "$f2"; 
      $ctm = strftime $dft, localtime($b[9]);
    } else {
      $ctm = '';
      $s->echo_msg("WARN: could not find file - $f2.", 2); 
    } 
    $tit = sprintf "S%03dJ%04dH%05d", $sid, $jid, $hid;
    $sub = sprintf "S%05d${ds}J%05d${ds}H%05d$ds%d", $sid, $jid, $hid, $hms;
    $sb2 = sprintf "S%05d${ds}J%05d${ds}H%05d$ds%d", $sid, $jid, $hid, $hms;
    $r->{$sid} = [] if !exists $r->{$sid}; 
    push @{$r->{$sid}}, {dsp=>"$dsp$f2",ctm=>$ctm,fn=>$fn,f2=>$f2,t=>$tit,
      rdr=>$rdr,adr=>$adr, sub=>$sub,
#      ffn=>"$rdr/$fn",
      ffn=>$f2,
      dsp_owb=>"$dsp_owb$ds$sn$ds$sub", ptm=>$b[9], 
      dsp_dir=>"$dsp_dir$ds$sn$ds$sb2"
      };
    # print "$a[$i] - $sid:$jid:$hid:$hms:$ctm<br>\n"; 
  }
  $s->echo_msg($r,3);

  # 6. archive the reports
  $s->echo_msg("6. archive reports", 2); 
  foreach my $k (sort keys %$r) {
    for my $i (0..$#{$r->{$k}}) {
      my $p   = $r->{$k}[$i]; 
      my $tm1 = $p->{ptm}; 
      my $rd  = $p->{rdr};
      my $sd  = $p->{sub};
      my $ffn = $p->{ffn};			# from file name
      my $fn  = $p->{fn};			# just file name
      my $dr  = join $ds, $adr, $sd;		# output dir
      my $ofn = join $ds, $adr, $sd, $fn; 	# output file name
      my ($f_n, $f_p, $sfx) = fileparse($ffn,qr{\..*});  
      if ($^O =~ /^MSWin/i) {
          $f_p =~ s/\\$//; 	# remove the ending $ds
      } else {
          $f_p =~ s/\/$//; 	# remove the ending $ds
      }
      # 6.1 check if the target file exist and older than current on
      $s->echo_msg("INFO: 6.1 - check file $ofn...", 3);
      if (-f $ofn) {
        my $tm2 = (stat $ofn)[9]; 
        if ($tm2 > $tm1) {  
          $s->echo_msg("INFO: $fn - skipped.", 3); 
          next; 
        }
      } 
      $s->echo_msg("INFO: $ffn<br>--->: $ofn...",1); 
      # 6.2 make target dir
      $s->echo_msg("INFO: 6.2 - check dir $dr...", 3);
      if (!-d $dr) { 
        $s->echo_msg("INFO: mkpath - $dr", 3);      
        eval { mkpath($dr) };
        $s->echo_msg("ERR: couldn't create $dr: $@", 0) if ($@);
      } 
      # 6.3 copy the css style file to the target folder
      $s->echo_msg("INFO: 6.3 - copy file $css_style to $dr...", 3);
      copy $css_style, $dr	if $css_style; 

      # 6.4 open the index file and target file
      $s->echo_msg("INFO: 6.4 - read from $ffn...", 3);
      if (! -f $ffn) { 
        $s->echo_msg("WARN: 6.4 - could not find file $ffn.", 3);
        next; 
      }      
      if (!(open IDX, "<$ffn")) {
          $s->echo_msg("ERR: could not open file - $ffn: $!",0);
          next; 
      }
      $s->echo_msg("INFO: 6.4 - write to  $ofn...", 3);
      if (! (open OFN, ">$ofn")) {
        $s->echo_msg("ERR: could not write to file - $ofn: $!",0);
        next; 
      } 
      while (<IDX>) {
        my $rec = $_; 
        # href="http://ors2di/cgi/dsp.pl?t=vpapp2&f=logs/rpts/rpt92_287_646_115805_10268.htm"
        # href="http://ors-owbtest2:7777/cgi/cpp2.pl?pid=ckpt&target=vpapp2&task=disp_file&f=\\vpapp2\share\ckpt_vpapp2\rpts\OracleServicesAdmin\2012\01\09\rpt236_812_1728_173640_10007.htm"
        my ($f0,$f1) = ($rec =~ m/\"(http:.+)(rpt\d+_\d+_\d+_\d+_\w+\.\w+)\"/); 
        if ($f0 && $f1) {
          my $ifn2 = join $ds, $f_p, $f1;
          my $ofn2 = join $ds, $adr, $sd, $f1; 
          $rec =~ s/\"(http:.+)\"/\"$f1\"/; 
          $s->echo_msg("INFO: copying $ifn2 to $ofn2",3);          
          # copy($ifn2,$ofn2); 
          if (!(open IFN2, "<$ifn2")) {
            $s->echo_msg("ERR: (IFN2) could not open - $ifn2: $!",0);
            next; 
          }
          if (!(open OFN2, ">$ofn2")) {
            $s->echo_msg("ERR: (OFN2) could not write to $ofn2: $!",0);
            close IFN2; 
            next;
          }
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
  my $gzp_prg = "";
     $gzp_prg = $ar->{arch_prg} if exists $ar->{arch_prg}; 
  my $ad2 = "$adr/archived"; 
  if (!-d $ad2) { 
    $s->echo_msg("INFO: mkpath - $ad2", 3);      
    eval { mkpath($ad2) };
    $s->echo_msg("ERR: ($prg) couldn't create $ad2: $@", 0) if ($@);
  } 
  my ($css_fn, $path, $sfx) = fileparse($css_style,qr{\..*});
  foreach my $k (sort keys %$r) {
    for my $i (0..$#{$r->{$k}}) {
      my $p   = $r->{$k}[$i]; 
      my $dp  = $p->{dsp}; 
      my $rd  = $p->{rdr};
      my $tm  = $p->{ptm}; 
      my $fn  = $p->{fn};
      my $sd  = $p->{sub};
      my $elp = time - $tm; 
      my $rt  = $fn; $rt =~ s/_index\.htm//; 
      my $sd2 = $sd; $sd2 =~ s/\/\w+$//; 
      my ($tf1,$tf2) = (); 
      if ($^O =~ /^MSWin/i) {
        $tf1 = join $ds, $ad2, "$rt.tar";
        $tf2 = join $ds, $adr, $sd2, "$rt.tar"; 
        if ($gzp_prg && -f $gzp_prg) {
          # $p->{dsp_tgz} = "$dsp_owb/$sn/$sd2/$rt.tar.gz"; 
          $p->{dsp_tgz} = join $ds, "$dsp$p->{adr}",$p->{sub},"$rt.tar.gz";
          $p->{fn_tgz}  = "$rt.tar.gz"; 
        } else { 
          # $p->{dsp_tgz} = "$dsp_owb/$sn/$sd2/$rt.tar"; 
          $p->{dsp_tgz} = join $ds, "$dsp$p->{adr}",$p->{sub},"$rt.tar";
          $p->{fn_tgz}  = "$rt.tar"; 
        } 
      } else {
        $tf1 = join $ds, $ad2, "$rt.tgz";
        $tf2 = join $ds, $adr, $sd2, "$rt.tgz"; 
        # $p->{dsp_tgz} = "$dsp_owb/$sn/$sd2/$rt.tgz";
        $p->{dsp_tgz} = join $ds,"$dsp$p->{adr}",$p->{sub},"$rt.tgz";
        $p->{fn_tgz}  = "$rt.tgz"; 
      }
      my ($tm1, $tm2) = (0,0); 
      $tm1 = (stat $tf1)[9] if -f $tf1; 
      $tm2 = (stat $tf2)[9] if -f $tf2; 
      if ($tm > $tm1 || $elp >= $rpt_kp) { 
        $s->echo_msg("INFO: reading $rd...", 2); 
        opendir RD, "$rd" || $s->echo_msg("WARN: (RD) could not opendir - $rd: $!", 0); 
        my @a = map {join $ds, $rdr, $_; } sort grep !/\.bak$/, (grep /$rt/, readdir RD);
        closedir RD;
        $p->{old_fns} = [];
        for my $i (0..$#a) { $p->{old_fns}[$i] = $a[$i]; } 
      }
      # archived the original files
      if (!-f $tf1 || $tm > $tm1) {
        unlink $tf1 	if -f $tf1;
        my $fh1; 
        my $tar = Archive::Tar->new();
        if ($^O =~ /^MSWin/i) {
          $fh1 = new IO::File " > $tf1";
        } else { 
          $fh1 = new IO::File "| /usr/bin/compress -c > $tf1";
        }
        $tar->setcwd($rd);
        $tar->add_files(@{$p->{old_fns}});
        $tar->write($fh1);
        $fh1->close ; 
        if ($^O =~ /^MSWin/i && $gzp_prg && -f $gzp_prg) {
          system($gzp_prg, $tf1) == 0 || 
          $s->echo_msg("ERR: could not run $gzp_prg $tf1",0); 
        }
      }
      # archived formated files
      if (!-f $tf2 || $tm > $tm2) {  
        unlink $tf2 	if -f $tf2;
        my $d2 = join $ds, $adr, $sd; 
        opendir RD, "$d2" || $s->echo_msg("WARN: could not opendir - $d2: $!", 0); 
        my @b = map {join $ds, $d2, $_; } sort grep !/\.bak$/, (grep /$rt/, readdir RD);
        closedir RD;
        my $fh2; 
        my $ta2 = Archive::Tar->new();
        if ($^O =~ /^MSWin/i) {
          $fh2 = new IO::File " > $tf2";
        } else { 
          $fh2 = new IO::File "| /usr/bin/compress -c > $tf2";
        }
        $ta2->setcwd("$d2");
        $ta2->add_files(@b);
        $ta2->write($fh2);
        $fh2->close ;
        if ($^O =~ /^MSWin/i && $gzp_prg && -f $gzp_prg) {
          system($gzp_prg, $tf2) == 0 || 
          $s->echo_msg("ERR: could not run $gzp_prg $tf2",0); 
        }
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
    my $m = "ERR: ($prg) no report from $rdr is found"; 
       $m .= " for Study $study_id" 	if $study_id || $study_id == 0; 
       $m .= " , Job $job_id" 		if $job_id   || $job_id   == 0; 
       $m .= " , HJob $hjob_id"		if $hjob_id  || $hjob_id  == 0; 
    $s->echo_msg($m, 0); 
#    return; 
  }

  my $f_li = "  <li><b>%s - %s</b></li>\n";
  my $f_la = "  <li><a href='%s' target=_new title='%s'>%s</a> (%s)</li>\n"; 
  my $f_l2 = "  <li><a href='%s' target=_new title='%s'>%s</a> \[created at %s\] (%s)</li>\n"; 
  my $f_aa = "  <a href='%s' target=R title='%s'>%s</a> (%s)\n"; 
  my $f_a2 = "<a href='%s' target=_blank title='%s'>%s</a>"; 
  my $t = "<ul>\n"; 
  foreach my $k (sort keys %$r) {
    $t .= sprintf $f_li, $k, $sd->{$k}; 
    $t .= "  <ul>\n";
     for my $i (sort {$r->{$k}[$a]{ctm} cmp $r->{$k}[$b]{ctm} } 0..$#{$r->{$k}}) {
      my $p = $r->{$k}[$i]; 
      my $tgz = join $ds, $p->{adr}, $p->{sub}, $p->{fn_tgz}; 
      my $s1 = "$p->{fn_tgz} [created at $p->{ctm}]"; 
      my $s2 = join $ds, $p->{dsp_dir}, $p->{fn}; 
      my $t2 = sprintf $f_a2, $s2, $p->{ffn},$s2; 
#      if (exists $p->{old_fns}) { 
         # $t .= sprintf $f_la, $p->{dsp_tgz}, $p->{t}, $s1, $s2; 
         $t .= sprintf $f_l2, $tgz, $p->{t}, $p->{fn_tgz},$p->{ctm}, $t2; 
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
  if ($study_id != 0 && !$study_id) {
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
    $t .= sprintf $f_tr, @rec if $#rec >= 0; 
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

History: mm/dd/yyyy (developer) - description

  03/28/2011 (htu) - added $exc_vars
  03/29/2011 (htu) - added $obj_vars

=cut

sub disp_tabs {
  my ($s, $q, $ar) = @_;
  
  # 1. get variables
  my $prg = 'disp_tabs';
  my ($sn,$odr,$rdr,$dsp,$study_id,$study_name,$tnm,$xnm) = (); 
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
  $tnm	= '%FINAL'			if !$tnm; 
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
  $xnm  = ''				if !$xnm; 

  # 2. check required elements
  if (!$sn) {
    $s->echo_msg("ERR: server name is not defined.", 0);  return; 
  }
  if ($study_id != 0 && !$study_id) {
    $s->echo_msg("ERR: study_id is not provided.", 0);  return; 
  }

  # 3. get study schema and DBL

  my $whr = "where study_id = $study_id order by study_id"; 
  my $rr = $s->run_sqlcmd($ar,'stg_schema,stg_dbl','cc_studies', $whr);
  
  if ($#$rr < 0) {
    $s->echo_msg("ERR: could not find study_id - $study_id in study table.", 0); 
    return;
  }
  my $stg_sch = uc $rr->[0]{stg_schema}; 
  my $stg_dbl = uc $rr->[0]{stg_dbl};
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
    my $m = "ERR: no table is found for Study $study_id ($tnm)."; 
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
  
  my $prg = 'AppBuilder::TaskDisps->disp_rpts';
  # 1. get variables
  $s->echo_msg(" 1. Get variables...", 2); 
  my ($sn,$odr,$rdr,$dsp) = (); 
  my $pid = (exists $ar->{pid}) ? $ar->{pid} : '';
  my $drv = (exists $ar->{drv_map}) ? $ar->{drv_map} : '';
  my $ds  = (exists $ar->{dir_sep}) ? $ar->{dir_sep} : '';
     $ds  = ($^O =~ /^MSWin/i) ? '\\' : '/' 	if ! $ds; 
  
  $sn  = $ar->{sid}  		if exists $ar->{sid};
  $sn  = $ar->{target}  	if exists $ar->{target}  && !$sn;
  $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
  $drv = '\\\\$sn'		if ! $drv; 
  $odr = eval $s->set_param('out_dir', $ar); 		# output dir
  $rdr = $odr->{$sn}{rpt};  				# rpt dir
  $dsp = (exists $odr->{$sn}{dsp}) ? $odr->{$sn}{dsp} : $ar->{script_url};	# dsp url
  $dsp .= '?' . "pid=$pid&target=$sn&task=disp_file";
  $dsp .= '&' . "f=";
  my $study_id 	= (exists $ar->{study_id})   ? $ar->{study_id}   : '';
  my $study_name= (exists $ar->{study_name}) ? $ar->{study_name} : ''; 

  $s->echo_msg("INFO: RDR - $rdr<br>\nDSP - $dsp",3);

  # 2. check required elements
  $s->echo_msg(" 2. Check required elements...", 2); 
  if (! -d $rdr) {
    $s->echo_msg("ERR: ($prg) could not find rpt dir - $rdr.", 0);  return; 
  }

  # 3. get study id
  $s->echo_msg(" 3. Get study ID...", 2); 
  my $studyid = $s->get_studyid($ar); 			# study ids
  my $sd = {};						# study id hash array
  for my $i (0..$#$studyid) { 
    $sd->{$studyid->[$i][0]} = $studyid->[$i][1];
  }
  $s->echo_msg($sd, 5); 

  # 4. get all index files  
  $s->echo_msg(" 4. Get all index files from $rdr...", 2); 
  my $fname = 'index';

  # 01/05/2012: let's get the out dir stored in cc_hist_jobs table
  my $rr  = $s->get_htmlrpts($ar); 

  # 5. loop through each file
  $s->echo_msg(" 5. Loop through each file...", 2); 
  my $r = {}; 						# result array ref
  for my $i (0..$#$rr) {
    my $sid = $rr->[$i]{sid}; 
    $r->{$sid} = [] if !exists $r->{$sid}; 
    push @{$r->{$sid}}, $rr->[$i]{stat};
  }
  
  # 6. print the html
  $s->echo_msg(" 6. Print HTML doc...", 2); 
  if (!@$rr) {
    $s->echo_msg("ERR: no report is found for study $study_id - $study_name.",0);
    return;
  }

  my $f_li = "  <li><b>%s - %s</b></li>\n";
  my $f_la = "  <li><a href='%s' target=R title='%s'>%s</a> (%s)</li>\n"; 
  my $t = "<ul>\n"; 
  foreach my $k (sort keys %$r) {
    $t .= sprintf $f_li, $k, $sd->{$k}; 
    $t .= "  <ul>\n";
    for my $i (sort {$r->{$k}[$a]{ctm} cmp $r->{$k}[$b]{ctm} } 0..$#{$r->{$k}}) {
      my $p = $r->{$k}[$i]; 
      $t .= sprintf $f_la, $p->{dsp}, $p->{fn}, $p->{t}, 
          "reported at $p->{rtm} and created at $p->{ctm}"; 
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

  my $whr = 'ORDER BY client_id'; 
  my $r = $s->run_sqlcmd($ar, 'client_id,client_name', 'cc_clients', $whr);   
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

  my $whr = "";
  $whr = "WHERE client_id=$ar->{cln_id} ORDER BY prj_id " 
    if exists $ar->{cln_id} && ($ar->{cln_id} =~ /^\d+$/);
  my $r = $s->run_sqlcmd($ar, 'prj_id,prj_name', 'cc_projects', $whr);   
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

  my $whr = " WHERE study_status = 1";
  $whr .= " AND prj_id=$ar->{prj_id}" 
    if exists $ar->{prj_id} && ($ar->{prj_id} =~ /^\d+$/);
  $whr .= ' ORDER BY study_id ';
  my $r = $s->run_sqlcmd($ar, 'study_id,study_name', 'cc_studies', $whr);   
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

=cut

sub disp_job {
  my ($s, $q, $ar) = @_;

  my $whr = "";
  $whr = "WHERE study_id=$ar->{study_id}" 
    if exists $ar->{study_id} && $ar->{study_id} =~ /^\d+$/;
  $whr .= " ORDER BY job_id"; 
  my $r = $s->run_sqlcmd($ar, 'job_id,job_name', 'cc_jobs', $whr);   
  print   $s->build_links($r, $ar);     
  return;
} 

=head2 disp_hjob($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_hjob {
  my ($s, $q, $ar) = @_;

  my $sql = "ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';\n";
  $sql .= "SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;\n";
  $sql .= "SELECT '==,'||hjob_id||','||replace(job_action,',','#') as record ";
  $sql .= "FROM cc_hist_jobs "; 
  if (exists $ar->{job_id} && ($ar->{job_id} =~ /^\d+$/)) {
    $sql .= " WHERE job_id = $ar->{job_id} ORDER BY hjob_id; \n";
  } else {
    $sql .= ";\n"; 
  }  
  my $rst  = $s->open_cmd($sql,$ar); 
  my $vr = ['hjob_id','job_action']; 
  $ar->{var_arf} = $vr; 
  my $rr  = $s->parse_records($rst, $vr, '==', ','); 

  for my $i (0..$#$rr) {
    $rr->[$i]{job_action} =~ s/\#/,/g; 
  }
  
  # $s->disp_param($rr); 
 
  print $s->build_links($rr, $ar);     
  return;
} 

=head2 disp_htmlrpt($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub disp_htmlrpt {
  my ($s, $q, $ar) = @_;

  my $rr = $s->get_htmlrpts($ar); 
  my $f_la = "  <li><a href=\"%s\" target=\"%s\" title=\"%s\">%s</a> (%s)\n"; 

  my $t = "<ul>\n"; 
  for my $i (0..$#$rr) {
    my $url = $rr->[$i]{stat}{dsp};
    my $tit = $rr->[$i]{stat}{fn};
    my $sta = $rr->[$i]{job_status};
    my $txt = "Reported at $rr->[$i]{stat}{rtm}; ";
      $txt .= "Created at $rr->[$i]{stat}{ctm}";
    $t .= sprintf $f_la, $url, "R", $tit, $sta, $txt; 
  } 
  $t .= "</ul>\n"; 
  print $t;     
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

  my $prg = 'TaskDisp->build_links';   
  # 0 - return if $pr is empty
  if (!$pr || $#$pr < 0) {
    $s->echo_msg("WARN: ($prg) No records.",0); return; 
  }

  # 1. define variables
  $s->echo_msg(" 1. Define variables...", 2); 
  my $pid = (exists $ar->{pid}) ? $ar->{pid} : '';
  my $sid = (exists $ar->{sid}) ? $ar->{sid} : ''; 
     $sid = $ar->{sel_sn1}	if !$sid && exists $ar->{sel_sn1}; 
  my $tsk = (exists $ar->{task}) ? $ar->{task} : ''; 	# such as disp_client  
  my $tgt = (exists $ar->{fr_tgt}) ? $ar->{fr_tgt} : '';	# frame target
     $tgt = 'R'		if ! $tgt; 

  my $tk = $tsk; $tk =~ s/(disp_)//;  
  my $tr = {'client'=>'project','project'=>'study','study'=>'job','job'=>'hjob' };
  my $br = {'client'=>'','project'=>'cln','study'=>'prj','job'=>'study'
           ,'hjob'=>'job' };
  my $tg = {'client'=>'D2','project'=>'D3','study'=>'D4','job'=>'R' };
  my $id = {'client'=>'cln_id','project'=>'prj_id','study'=>'study_id'
           ,'job'=>'job_id','hjob'=>'hjob_id' };
  my $nm = {'client'=>'cln_name','project'=>'prj_name','study'=>'study_name'
           ,'job'=>'job_name','hjob'=>'hjob_name' };

  my $url = $ar->{web_url};   			# web URL
     $url =~ s/(\?.*)//    	if $url;	# remove parameters
     $url .= "?pid=$pid&sel_sn1=$sid"; 
  $s->echo_msg("INFO: TASK=$tk, URL=$url", 3);      
  $s->echo_msg($pr,3);
    
  # 2. check required variables 
  $s->echo_msg(" 2. Check required variables...", 2); 
  if (!$pid) {
    $s->echo_msg("ERR: ($prg) could not find pid.",0); return;
  }
  if (!$sid) {
    $s->echo_msg("ERR: ($prg) could not find sid.",0); return;
  }
  $s->echo_msg("INFO: PID=$pid, SID=$sid", 3); 

  # 3. build links
  $s->echo_msg(" 3. Build links...", 2); 
  my $f_aa = "  <a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n"; 
  my $f_bb = "<b>%s</b>\n";
  my $f_li = "  <li>%s</li>\n";

  my $vr   = $ar->{var_arf};   
  my $u_lf = "$url&task=disp_usr_task";
  my ($u_rt, $u_ct) = ();
  if (exists $tr->{$tk} && $tr->{$tk}) { 
    $u_rt = "$url&task=disp_$tr->{$tk}"; 
    $u_ct = "$url&task=disp_new&new_task=add_$tr->{$tk}"; 
  } 
  $s->echo_msg("INFO: ULT=$u_lf, UCT=$u_ct, URT=$u_rt", 3);
  $s->echo_msg($id, 3);
  
#  my $ids  = 'cln_id,prj_id,study_id,job_id,hjob_id'; 
  my $cnt_ar = {}; 
  foreach my $kk (keys %$id) {
    my $k = $id->{$kk}; 
    my $n = $nm->{$kk}; 
    if ($kk eq $tk) { 
      $s->echo_msg("WARN: skipped ID for $tk.", 3); 
      next; 			# so that we do not duplicated the id
    }
    if (exists $ar->{$k} && $ar->{$k} =~ /^\d+$/) { 
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
  $s->echo_msg("WARN: ULT=$u_lf",3);
  $s->echo_msg("WARN: UCT=$u_ct",3);
  $s->echo_msg("WARN: URT=$u_rt",3); 
  my $ar_id = {}; 
  foreach my $k (sort keys %$ar) { next if $k !~ /id$/i; $ar_id->{$k} = $ar->{$k}; }
  $s->echo_msg($ar_id, 3); 

  my $t = "<center>" . (sprintf $f_bb, uc($tk)) . ': ';
#     $t = sprintf $f_aa, "$url&task=disp_new&new_task=add_$tk", 'R', "Add $tk", $t; 
#     $t .= "<ul>\n"; 
  my $v_id = $vr->[0];
  my $v_nm = $vr->[1]; 
  $s->echo_msg("INFO: VID=$v_id, VNM=$v_nm",3);   

  my $k1 = $br->{$tk} . '_id'; 
  my $n1 = $br->{$tk} . '_name'; 
  my $kn = (exists $ar->{$n1}) ? "$ar->{$k1} - $ar->{$n1}" : "Add $tk"; 
  my $u1 = "$url&task=disp_new&new_task=add_$tk"; 
  $t .=  (sprintf $f_aa, $u1 ,"R","Add $tk",$kn) . "</center>";
  $t .= "<br>\n"; 
  $s->echo_msg("INFO: K1=$k1, N1=$n1, U1=$u1", 3);  

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
       $t1 .= sprintf $f_aa, $u, 'R', "Show Stat for HJob - $k", 'S'; 
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
     $url =~ s/(\?.*)//  if $url; 			# remove parameters
     $url .= "?pid=ckpt";
     $url .= "&sel_sn1=$sn"		if $sn; 
  my $f_sid = (exists $ar->{study_id} && $ar->{study_id} =~ /^\d+$/) ? 1 : 0;   
  my $study_id = ($f_sid) ? $ar->{study_id} : ''; 
  $url .= "&study_id=$study_id"		if $f_sid; 

  my $t = ""; 
  for my $i (0..$#$avl) { 
    my $k = $avl->[$i];
    my $v = $alb->{$k};
    next if $k =~ /^0$/; 
    if ($k =~ /^\d+/) {
      if ($k !~ /^0$/) {
        $t .= "</ul>\n";
        $v =~ s/_//g	if $v; 
        $t .= sprintf $f_bb, "$k - $v";     
      } 
      next; 
    } 
    $t .= sprintf $f_li, "$url&task=$k&a=help", $v  
  }
  $s->disp_task_form($q,$ar,$t); 
  
  return;

} 

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from jp2.pl on 09/08/2010.

=item * Version 0.20

  09/08/2010 (htu): 
    1. start this PM
  01/05/2012 (htu): added disp_htmlrpt

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

