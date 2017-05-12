package CGI::AppBuilder::MapSpec;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Path; 
# use Net::Rexec 'rexec';

our $VERSION = 0.10;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(	run_ldspecs run_ldviews
                   );
our %EXPORT_TAGS = (
    plsql => [qw(run_ldspecs )],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::MapSpec - ETL map specifications module

=head1 SYNOPSIS

  use CGI::AppBuilder::MapSpec;

  my $sec = CGI::AppBuilder:MapSpec->new();
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

=head2 run_ldspecs($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:

  
Variables used or routines called:

  None

Return: $pr will contain the parameters adn output from running the PL/SQL.


=cut


sub run_ldspecs {
  my ($s, $ar) = @_;

  my $prg = 'run_ldsepcs'; 
  # 0. prepare parameters and check parameters 
  my ($spv, $rt1) = ();
  my $lst_tab	= 'sp_lists';				# list tab name
  my $spc_tab	= 'sp_specs'; 				# spec tab name
  my $job_tab	= 'sp_jobs';				# table: sp_jobs
  my $wsn	= 'ALL_VARS';				# spreadsheet name
  # get parent id, server id, study id and list id
  my $vs = 'pid,sid,study_id,list_id'; 
  my ($pid,$sn,$sid,$lid) = $s->get_params($vs,$ar); 
    $sid = 0 if !$sid; 
    $lid = 0 if !$lid; 

  # $sid = $ar->{study_id} if exists $ar->{study_id} && $ar->{study_id}; 
  # $lid = $ar->{list_id}  if exists $ar->{list_id}  && $ar->{list_id};
  $rt1 = $ar->{xls_list} if exists $ar->{xls_list} && $ar->{xls_list}; 
  # $rt1 = $ar->{sel_sn2}  if !$rt1 && exists $ar->{sel_sn2} && $ar->{sel_sn2}; 

  print $s->disp_header(undef,$ar); 
  
  if (!$lid) {
    $s->echo_msg("ERR: ($prg) LIST ID is required.", 0);
    return; 
  }
  if (!$rt1) {
    $s->echo_msg("ERR: ($prg) no XLS file is selected.", 0);
    return; 
  }

  my $ds = '/'; 
     $ds = '\\' if $^O =~ /MSWin/i; 
  my $ad 	= eval $s->set_param('all_dir', $ar); 	# all dir array
  my $dir 	= $ad->{$sn}{map};			# map dir
  #  $dir	= join $ds, $dir, (sprintf "${sn}_%03d%03d", $sid,$lid);
     $dir	= join $ds, $dir, (sprintf "${sn}_%03d", $sid);     
  my $sqlout	= $ad->{$sn}{sqlout};			# sql output dir
  my $odr	= "$sqlout$ds$sn";
  my $rt	= $rt1;	$rt =~ s/\.xls$//i;		# BUP115_DCS
  my $fn	= "$dir$ds$rt.xls";			# input  file name
  my $dtm	= strftime "%Y%m%d_%H%M%S", localtime; 
  my $ymd	= strftime "%Y$ds%m$ds%d", localtime;
  my $sdr	= join $ds, $odr, $ymd; 
  my $otf	= "${rt}_vars_$dtm.sql";		# output file name
  my $ofn 	= "$sdr$ds$otf"; 			# output file full ame
  $s->echo_msg("INFO: ($prg) rt1=$rt1; rt=$rt; dir=$dir<br>\n",2); 
  if ($fn =~ /\s+/) {
    $s->echo_msg("ERR: ($prg) there is space in file name - $fn.", 0);
    $s->echo_msg("INFO: please remove the spaces in the file name!", 0);
    return; 
  }
  if (!-f $fn) {
    $s->echo_msg("ERR: ($prg) could not find XLS file - $fn.", 0);
    return; 
  }
  if (!-d $sqlout) {
      eval { mkpath($sqlout,0,0777) };
      croak "ERR: could not mkdir - $sqlout: $!: $@<br>\n" if ($@);
      system("chmod -R ugo+w $sqlout") 		if ($^O !~ /^MSWin/i); 	# non window
  } 
  if (!-d $odr) {
      eval { mkpath($odr,0,0777) };
      # mkdir $odr; 
      croak "ERR: could not mkdir - $odr: $!: $@<br>\n" if ($@);
      system("chmod -R ugo+w $odr") 		if ($^O !~ /^MSWin/i); 	# non window
  } 
  if (!-d $sdr) {
    my $y4	= strftime "%Y", localtime;
    my $mn	= strftime "%m", localtime;
    my $dy	= strftime "%d", localtime;
    my @a 	= ();
    push @a, (join $ds, $odr, $y4);
    push @a, (join $ds, $odr, $y4, $mn);
    push @a, (join $ds, $odr, $y4, $mn, $dy);
    for my $i (0..$#a) { 
      my $dd = $a[$i]; 
      if (!-d $dd) { 
        eval { mkpath($dd,0,0777) }; 
        croak "ERR: could not mkdir - $dd: $!: $@<br>\n" if ($@);
        system("chmod -R ugo+w $dd") 		if ($^O !~ /^MSWin/i); 	# non window
      } 
    }
  } 

  # 1. get list information
  $s->echo_msg(" 1. get list info for list id $lid...", 1); 
  my $whr = " WHERE  list_id = $lid ";
  my $cns = 'study_id,sponsor,project_code,project_name,study_name,sp_analyst';
    $cns .= ',sp_version,sp_source,standard'; 
  my $r1 = $s->run_sqlcmd($ar, $cns, 'sp_lists', $whr);
  $s->echo_msg($r1, 5);
  $sid = $r1->[0]{study_id} 	if !$sid; 
  $spv = $r1->[0]{sp_version}	if !$spv;
  
  # 2. read the XLS file
  $s->echo_msg(" 2. read XLS file - $fn...", 1); 
  my $pr  = $s->read_xls($fn, $wsn); 
  if (!$pr || ref($pr) !~ /^ARRAY/i) {
    $s->echo_msg("ERR: ($prg) Did not get any record from the file: $fn", 0);
    my $m = "Please check the followings: <br>";
      $m .= "  * Make sure that the file is not password-protected<br>\n";
      $m .= "  * Make sure that there is a tab 'ALL_VARS' in the file<br>\n";
      $m .= "  * Make sure that you have used a correct spec template<br>\n";
    $s->echo_msg("INFO: ($prg) $m", 0);   
    return; 
  }
  $s->echo_msg("INFO: ($prg) no of records: $#$pr", 1);
  my $r2 = {list_id 	=> $lid
    , study_id		=> $sid
    , project_code	=> $pr->[0][3]
    , project_name	=> $pr->[1][3]
    , sponsor		=> $pr->[2][3]
    , sp_date		=> $pr->[3][3]
    , sp_analyst	=> $pr->[4][3]
    , study_name	=> $pr->[5][3]
    , standard		=> $pr->[6][3]
    , sp_version	=> $spv
    , sp_source		=> $fn
    };
  $s->echo_msg($r2, 5);

  # 3. build SQL statement for sp_jobs
  $s->echo_msg(" 3. build sql statement for sp_jobs...", 1); 
  my $sql 	= [];		# sql array 

  # get job id
  $cns = 'sp_jobs_seq.nextval as jid'; 
  my $r3 = $s->run_sqlcmd($ar, $cns, 'dual', '');
  my $jid = $r3->[0]{jid}; 

  if ($jid) { 
    my $ctx = 'sp_context_pkg'; 
    my $job_ins  = "PROMPT Inserting into $job_tab ...\n";
       $job_ins .= "INSERT INTO $job_tab ( job_id, list_id, job_name \n";
       $job_ins .= "  , job_args, job_type, job_crttime \n";
       $job_ins .= "  , job_starttime, job_inpath, job_outpath \n";
       $job_ins .= "  , db_user, os_user, app_user \n";
       $job_ins .= "  ) VALUES ($jid, $lid, null \n"; 
       $job_ins .= "  , 'sid=$sid,lid=$lid,dnm=ALL_VARS','LDSPECS', sysdate \n";
       $job_ins .= "  , sysdate, '$fn', '$ofn' \n";
       $job_ins .= "  , USER, $ctx.get_os_user, $ctx.get_app_user \n";
       $job_ins .= "  );\n"; 
    push @$sql, $job_ins;      
  }
  
  # 4. build SQL statement for sp_lists
  $s->echo_msg(" 4. build sql statement for sp_lists...", 1); 
  my $lst_vars ='study_id,project_code,project_name,sp_source';
    $lst_vars .= ',standard,study_name,sp_date,sp_analyst,sp_version';
    $lst_vars .= ',upd_date,sp_status'; 

  my $lst_sql = "UPDATE $lst_tab SET \n";
  my $tmp = '';
  foreach my $k (split /,/, $lst_vars) {
    my $v1 = $r1->[0]{$k};		# from sp_lists table
    my $v2 = $r2->{$k}; 		# from xls file
    # print "V1=$v1,V2=$v2<br>\n";     
    if ($k =~ /date$/i) { 
      $tmp .= ($tmp) ? "    , " : "      ";
      $tmp .= "$k = sysdate\n"; 
    } else {
      if ($v2 && uc($v2) ne uc($v1)) {
        $tmp .= ($tmp) ? "    , " : "      ";
        $v2 =~ s/\s*$//g;		# remove ending spaces
        $v2 =~ s/'/''/g;		# quote it for update
        $v2 =~ s/^\s*\n+//mg;		# remove multiple line breaks
        if ($k =~ /_id$/i) { 
          $tmp .= "$k = $v2\n";
        } else {
          $tmp .=  "$k = '$v2'\n";
        }
      }
    }
  } 
  $lst_sql .= "$tmp  WHERE list_id = $lid;\n";
  push @$sql, $lst_sql; 

  $s->echo_msg("SQL: ($prg) $lst_sql",1); 
  # $s->echo_msg($sql,5);

  # 5. build SQL statement for sp_specs
  $s->echo_msg(" 5. build sql statement for sp_specs...", 1); 
  my $spc_vars = 'spec_id,list_id,source_dataset,variable,type,format,label';
    $spc_vars .= ',sdtm_domain,sdtm_variable,mapping_comments';
    $spc_vars .= ',mapping_questions,pivot,notes';

  my $spc_del = "DELETE $spc_tab WHERE list_id = $lid;\n"; 
  push @$sql, $spc_del; 
    
  $cns = {};
  foreach my $k (split /,/, $spc_vars) {  $cns->{$k} = 1;   }
  my $r 	= [];		# record array
  my $c 	= [];		# column array 
  my $rec_cnt 	= -1; 		# record count

  for my $i (0..$#$pr) {  
    # get column names
    if ($pr->[$i][2] && $pr->[$i][2] =~ /source_dataset/i) {
      for my $j (2..$#{$pr->[$i]}) {
        my $k = lc $pr->[$i][$j]; 
           $k =~ s/^\s*//; $k =~ s/\s*$//; $k =~ s/ /_/g; 
        if (exists $cns->{$k}) { 
          $r->[0]{$k} = $k;
        } else {
          $s->echo_msg("  Col: $k - does not exist in table.", 2);
        }
        $rec_cnt = 0; 
        $c->[$j] = $k; 
      }
      next;
    } 
    next if $rec_cnt < 0;		# skip lines before column names
    my $nn = 0; 
    for my $j (2..$#{$pr->[$i]}) { $nn += 1  if $pr->[$i][$j];  }
    next if ! $nn; 			# skip if it is empty record

    $rec_cnt += 1;
    for my $j (2..$#{$pr->[$i]}) {
      my $k = $c->[$j]; 
      $r->[$rec_cnt]{$k} = (exists $pr->[$i][$j]) ? $pr->[$i][$j] : ""; 
    }

    my $sq2 = "INSERT INTO $spc_tab (\n";
    $tmp = ''; 
    foreach my $k (split /,/, $spc_vars) {
      $tmp .= ($tmp) ? "    , $k\n" : "    $k\n";    
    } 
    $sq2 .= "  $tmp  )\n  VALUES (\n";
    $tmp = '';
    foreach my $k (split /,/, $spc_vars) {
      my $v = $r->[$rec_cnt]{$k}; 
         $v =~ s/\s*$//g 	if $v;		# remove ending spaces
         $v =~ s/'/''/g  	if $v;		# double quote
         $v =~ s/^\s*\n+//mg 	if $v;		# remove multiple line breaks 
         $v =~ s/\&/and/g	if $v;		# replace & with and
      if ($k =~ /_id$/i) { 
        if ($k =~ /^spec/) {
          $tmp .= ($v) ? "    , $v\n" : "    , $rec_cnt\n";
        } else {
          $tmp .= ($v) ? "    , $v\n" : "    , $lid\n";
        }
      } elsif ($k =~ /date$/i) {
        $tmp .= "    , sysdate\n"; 
      } else {
        $tmp .= ($v) ? "    , '$v'\n" : "    , null\n";
      }
    }
    $tmp =~ s/^(\s*),/$1 /; 
    $sq2 .= "$tmp  );\n";
    push @$sql, $sq2; 
  }
  $s->echo_msg("INFO: ($prg) Rec count ($rec_cnt)",1); 
  $s->echo_msg($c,2);

  if ($jid) { 
    my $job_upd  = "PROMPT Updating $job_tab ...\n";
       $job_upd .= "UPDATE $job_tab SET job_endtime = sysdate \n";
       $job_upd .= "     , job_status = 'Completed successfully' \n";
       $job_upd .= " WHERE job_id = $jid ;\n";
    push @$sql, $job_upd;      
  } 

  # 6. output to file
  $s->echo_msg(" 6. output to file - $ofn...", 1); 

  open FN, ">$ofn" or croak "ERR: could not write to $ofn: $!\n";
#  print FN $lst_sql;
  for my $i (0..$#$sql) {  
#    print "$i/$#$sql \n"; 
    print FN "PROMPT $i/$#$sql \n"; 
    print FN "$sql->[$i]";  
    print FN "commit;\n" if ($i % 100 == 0); 
  }
#  print FN "exit\n"; 
  close FN; 

  # 7. output to file
  $s->echo_msg(" 7. run sql - $ofn...", 1);
  my $m2 = "File - $otf was written to $sdr"; 
  $s->echo_msg("INFO: ($prg) $m2", 1);
  my $rr = [];
  push @$rr, "$m2\n"; 
  my $f2 = $s->call_plsql($rr, $ar); 
  
  $s->disp_linkedfiles(undef, $ar, $f2); 
  
  wantarray ? @$r : $r;
}


=head2 run_ldviews($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:

  
Variables used or routines called:

  None

Return: $pr will contain the parameters adn output from running the PL/SQL.


=cut


sub run_ldviews {
  my ($s, $ar) = @_;

  my $prg = 'MapSpec::run_ldviews'; 
  # 0. prepare parameters and check parameters 
  my $lst_tab	= 'sp_lists';				# table: list tab name
  my $sty_tab	= 'sp_studies';
  my $vcd_tab	= 'sp_codes';				# table: sp_codes
  my $job_tab	= 'sp_jobs';				# table: sp_jobs
  my $wsn	= '(_VW|_TAB)$';			# spreadsheet name pattern

  my $id = 'study_id';
  my $f_sid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/)?1:0; 
  my $sid = ($f_sid) ? $ar->{$id} : '';
#  if ($sid !~ /^\d+$/) { 
#     $id = 'sid';
#     $f_sid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/)?1:0;      
#     $sid = ($f_sid) ? $ar->{$id} : '';
#  } 
     $id = 'list_id';
  my $f_lid = (exists $ar->{$id} && $ar->{$id} =~ /^\d+$/)?1:0; 
  my $lid = ($f_lid) ? $ar->{$id} : '';
     $id = 'xls_list'; 
  my $f_xls = (exists $ar->{$id} && $ar->{$id})?1:0;      
  my $rt1 = ($f_xls) ? $ar->{xls_list} : '';
  # $rt1 = $ar->{sel_sn2}  if !$rt1 && exists $ar->{sel_sn2} && $ar->{sel_sn2}; 

  print $s->disp_header(undef,$ar); 

  if ("$lid" ne "0" && !$lid) {
    $s->echo_msg("ERR: ($prg) LIST ID is required.", 0);
    return; 
  }
  # if ("$sid" ne "0" && !$sid) {
  #   $s->echo_msg("ERR: ($prg) Study ID is required.", 0);
  #   return; 
  # }
  if (!$rt1) {
    $s->echo_msg("ERR: ($prg) no XLS file is selected.", 0);
    return; 
  }

  my $ds = '/'; 
     $ds = '\\' if $^O =~ /MSWin/i; 
  my $pid	= $ar->{pid};				# parent id
  my $sn 	= $ar->{sid}; 				# server id
  my $ad 	= eval $s->set_param('all_dir', $ar); 	# all dir array
  my $dir 	= $ad->{$sn}{map};			# map dir
     $dir	= join $ds, $dir, (sprintf "${sn}_%03d", $sid);

  my $sqlout	= $ad->{$sn}{sqlout};			# sql output dir
  my $odr	= "$sqlout$ds$sn";
  my $rt	= $rt1;	$rt =~ s/\.xls$//i;		# BUP115_DCS
  my $fn	= "$dir$ds$rt.xls";			# input  file name

  my $dtm	= strftime "%Y%m%d_%H%M%S", localtime; 
  my $ymd	= strftime "%Y$ds%m$ds%d", localtime;
  my $sdr	= join $ds, $odr, $ymd; 
  my $otf	= "${rt}_vw_$dtm.sql";			# output file name
     $otf	=~ s/\$//g; $otf =~ s/[_]+/_/g; 
  my $ofn 	= "$sdr$ds$otf"; 				# output file full ame
  $s->echo_msg("INFO: ($prg) rt1=$rt1; rt=$rt; dir=$dir<br>\n",2); 
  if ($fn =~ /\s+/) {
    $s->echo_msg("ERR: ($prg) there is space in file name - $fn.", 0);
    $s->echo_msg("INFO: ($prg) please remove the spaces in the file name!", 0);
    return; 
  }
  if (!-f $fn) {
    $s->echo_msg("ERR: ($prg) could not find XLS file - $fn.", 0);
    return; 
  }
  if (!-d $sqlout) {
      eval { mkpath($sqlout,0,0777) };
      croak "ERR: ($prg) could not mkdir - $sqlout: $!: $@<br>\n" if ($@);
      system("chmod -R ugo+w $sqlout") 		if ($^O !~ /^MSWin/i); 	# non window
  } 
  if (!-d $odr) {
      # eval { mkpath($odr,0,0777) };
      mkdir $odr; 
      croak "ERR: ($prg) could not mkdir - $odr: $!: $@<br>\n" if ($@);
      system("chmod -R ugo+w $odr") 		if ($^O !~ /^MSWin/i); 	# non window
  } 
  if (!-d $sdr) {
      eval { mkpath($sdr,0,0777) }; 
      croak "ERR: ($prg) could not mkdir - $sdr: $!: $@<br>\n" if ($@);
      system("chmod -R ugo+w $sdr") 		if ($^O !~ /^MSWin/i); 	# non window
  } 

  # 1. get list information
  $s->echo_msg(" 1. get list info for list id $lid...", 1); 
  my $whr = " WHERE  list_id = $lid ";
  my $cns = 'study_id,sponsor,project_code,project_name,study_name,sp_analyst';
    $cns .= ',sp_version,sp_source,standard'; 
  my $r1 = $s->run_sqlcmd($ar, $cns, $lst_tab, $whr);
  $s->echo_msg($r1, 5);
  $sid = $r1->[0]{study_id} 	if ($sid !~ /^\d+$/);
  if ($sid !~ /^\d+$/) {
    $s->echo_msg("WARN: ($prg) no study id ($sid) is found for list_id=$lid.", 1); 
  } else {
    $s->echo_msg("INFO: study id ($sid) is found for list_id=$lid.", 1); 
  }
  $whr = " WHERE study_id = $sid ";
  $cns = "src_schema,stg_schema";
  my $r2 = $s->run_sqlcmd($ar, $cns, $sty_tab, $whr);
  my $src_sch = uc $r2->[0]{src_schema}; 
  my $stg_sch = uc $r2->[0]{stg_schema};
  
  # get job id
  $cns = 'sp_jobs_seq.nextval as jid'; 
  my $r3 = $s->run_sqlcmd($ar, $cns, 'dual', '');
  my $jid = $r3->[0]{jid}; 
  
  # 2. read the XLS file
  $s->echo_msg(" 2. read XLS file - $fn...", 1); 
  my $pr  = $s->read_xls($fn, $wsn, 1); 
  my $cr  = {}; 
  my $vvn  = ''; 
  for my $k (keys %{$pr}) { 
    my $sch = uc $pr->{$k}[1][2];		# C2: schema name
       $sch =~ s/^\s*//; $sch =~ s/\s*$//; 
    my $vwn = uc $pr->{$k}[2][2];		# C3: view name
       $vwn =~ s/^\s*//; $vwn =~ s/\s*$//;
    $vvn .= ($vvn) ? ",$vwn" : "$vwn";    
    my $vtp = uc $pr->{$k}[3][2];		# C4: view type
    my $vmg = "INFO: ($prg) number of records in $k($sch.$vwn\[$vtp\])";
    $s->echo_msg( "$vmg: $#{$pr->{$k}}", 1);
    if ("$sch" ne "$src_sch") {
      $s->echo_msg("WARN: ($prg) Schema names do not match: $sch <> $src_sch",0);
    } 
#    $sch = $src_sch 	if !$sch;  
    $sch = $src_sch	if $src_sch; 
    $vwn = $k 		if !$vwn;
    $vtp = 'VIEW'	if !$vtp; 
    my $i = -1;
    if ($vtp =~ /^DROP/i) {
      ++$i; 
      $cr->{$k}[$i] = {code_id => 'sp_codes_seq.nextval'
        , list_id	=> $lid
        , schema_name	=> $sch
        , obj_name	=> $vwn
        , obj_type	=> $vtp
        , seq_number	=> $i + 1
        , code_text 	=> "DROP $sch.$vwn"
      };
      next; 
    }
    for my $x (6..$#{$pr->{$k}}) {
      my $v = $pr->{$k}[$x][2];		# C7: view codes
      while (length($v) > 0) { 
        ++$i; 
        $cr->{$k}[$i] = {code_id => 'sp_codes_seq.nextval'
          , list_id	=> $lid
          , schema_name	=> $sch
          , obj_name	=> $vwn
          , obj_type	=> $vtp
          , seq_number	=> $i + 1
          , code_text 	=> substr($v,0,4000)
        };
        $v = substr($v,4000); 
      }
    }
  }
  if (!%$cr) {
    $s->echo_msg("WARN: ($prg) no view codes to be found in $fn.", 0); 
    return; 
  }
  $s->echo_msg($cr, 3);  
  # 3. build SQL statement for sp_codes
  $s->echo_msg(" 3. build sql statement for sp_codes...", 1); 
  my $sql 	= [];		# sql array 
  my $spc_vars = 'code_id,list_id,schema_name,obj_name,obj_type,seq_number';
    $spc_vars .= ',code_text';
  my $sel_cols = ''; 
  foreach my $k (split /,/, $spc_vars) {
    $sel_cols .= ($sel_cols) ? "    , $k\n" : "      $k\n";    
  } 
  if ($jid) { 
    my $ctx = 'sp_context_pkg'; 
    my $job_ins  = "PROMPT Inserting into $job_tab ...\n";
       $job_ins .= "INSERT INTO $job_tab ( job_id, list_id, job_name \n";
       $job_ins .= "  , job_args, job_type, job_crttime \n";
       $job_ins .= "  , job_starttime, job_inpath, job_outpath \n";
       $job_ins .= "  , db_user, os_user, app_user \n";
       $job_ins .= "  ) VALUES ($jid, $lid, null \n"; 
       $job_ins .= "  , 'sid=$sid,lid=$lid,dnm=$vvn','LDVIEWS', sysdate \n";
       $job_ins .= "  , sysdate, '$fn', '$ofn' \n";
       $job_ins .= "  , USER, $ctx.get_os_user, $ctx.get_app_user \n";
       $job_ins .= "  );\n"; 
    push @$sql, $job_ins;      
  }
  
  my $spc_del  = "PROMPT Deleting $vcd_tab ...\n";
     $spc_del .= "DELETE $vcd_tab WHERE list_id = $lid;\ncommit;\n\n"; 
  push @$sql, $spc_del; 

  for my $k (sort keys %$cr) {			# each tab
    if (! @{$cr->{$k}}) {
      $s->echo_msg("INFO: processing tab $k ...", 1); 
      $s->echo_msg("WARN: ($prg) no record for XLS tab - $k.",0);
      next; 
    }
    my $sch = $cr->{$k}[0]{schema_name}; 
    my $vwn = $cr->{$k}[0]{obj_name};
    my $vtp = $cr->{$k}[0]{obj_type};
    $s->echo_msg("INFO: processing tab $k ($sch.$vwn\[$vtp\])...", 1); 
    my $pmt = "PROMPT Inserting records for $vtp $vwn ... \n"; 
    push @$sql, $pmt; 
    my $t = '';
    my $n = $#{$cr->{$k}} + 1; 
    for my $i (0..$#{$cr->{$k}}) {		# each record
      my $j = $i + 1;
      my $p = "PROMPT $j/$n - $vcd_tab for $vtp $sch.$vwn ... "; 
      $t = ''; 
      foreach my $c (split /,/, $spc_vars) {	# each column
        my $v = $cr->{$k}[$i]{$c}; 
           $v =~ s/\s*$//g 	if $v;		# remove ending spaces
           $v =~ s/'/''/g  	if $v;		# double quote
           $v =~ s/^\s*\n+//mg 	if $v;		# remove multiple line breaks 
           $v =~ s/\&/and/g	if $v;		# replace & with and
        $t .= ($t) ? '    , ' : '      ';            
        if ($c =~ /(_id|_number)$/i) { 
          $t .= ($v) ? "$v\n" : "null\n";
        } else {
          $t .= ($v) ? "'$v'\n" : "null\n";
        }
      }
      $t = "\n$p\nINSERT INTO $vcd_tab (\n$sel_cols) VALUES (\n$t);\n"; 
      push @$sql, $t;
    }       
  }    

  if ($jid) { 
    my $job_upd  = "PROMPT Updating $job_tab ...\n";
       $job_upd .= "UPDATE $job_tab SET job_endtime = sysdate \n";
       $job_upd .= "     , job_status = 'Completed successfully' \n";
       $job_upd .= " WHERE job_id = $jid ;\n";
    push @$sql, $job_upd;      
  } 

  # 4. output to file
  $s->echo_msg(" 4. output to file - $ofn...", 1); 
  my $m2 = "File - $otf was written to $sdr"; 
  
  open FN, ">$ofn" or croak "ERR: ($prg) could not write to $ofn: $!\n";
  print FN "-- File name: $ofn\n";
  print FN "-- No of SQL: " . ($#$sql+1) . "\n"; 
  for my $i (0..$#$sql) {  
    print FN "$sql->[$i]";  
    print FN "commit;\n" if ($i != 0 && $i % 10 == 0); 
  }
  close FN; 
  $s->echo_msg("INFO: ($prg) $m2", 1);
  
  # 5. run sql files
  $s->echo_msg(" 5. run sql - $ofn...", 1);

  my $rr = [];
  push @$rr, "$m2\n"; 

  my $f2 = $s->call_plsql($rr, $ar); 
  $s->disp_linkedfiles(undef, $ar, $f2); 

  wantarray ? @$sql : $sql;
}


1;

=head1 HISTORY

=over 4

=item * Version 0.10

  This is the initial version ported from File::XLS2HTML test script on 11/17/2010.

=item * Version 0.20

  10/11/2011 (htu) - added run_ldviews 
  11/21/2011 (htu) - added sql codes to insert a reord to sp_jobs table 
                     in run_ldspecs and run_ldviews

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

