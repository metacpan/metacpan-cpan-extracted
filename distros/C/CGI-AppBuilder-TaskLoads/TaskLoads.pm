package CGI::AppBuilder::TaskLoads;

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
our @EXPORT_OK   = qw(ld_mdrstd get_ldrcfg build_dml cvt_ar2list cvt_ar2hr
  			get_insert_val get_update_val fmt_list2sel
                   );
our %EXPORT_TAGS = (
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::TaskLoads - Loading files to a database

=head1 SYNOPSIS

  use CGI::AppBuilder::TaskLoads;

  my $sec = CGI::AppBuilder::TaskLoads->new();
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

=head2 get_ldrcfg ($ar)

Input variables:

  $ar	- array ref containing the following variables:

Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref {$k}{$e} where $k = [v|1|..|study_id];
$e contains

  rdr - relative directory
  mfn - meta file name, i.e., the xls contains domain and variable metadata
  dfn - domain file name containing domain metadata
  vfn - variable file name containing variable metadata
  ofd - output file directory
  dml - data manipulation act: A|D|I|U
  var - hash array ref containing variables


=cut

sub get_ldrcfg {
  my ($s, $ar) = @_;

  my $prg = 'get_ldrcfg';
  my $ds = ($^O =~ /MSWin/i) ? '\\' : '/';
  my $sn 	= $ar->{sid}; 				# server id
     $sn  	= $ar->{sel_sn1} if !$sn && exists $ar->{sel_sn1};
  my $ad 	= eval $s->set_param('all_dir', $ar); 	# all dir array
  my $mlc	= $s->set_param('mdr_ldr_cfg', $ar); 	# meta dataloader cfg file
  my $dir 	= $ad->{$sn}{mdr};			# MDR dir
  my $r = {}; 				# result array
  if (!$sn) {
    $s->echo_msg("ERR: ($prg) server id is not provided.", 0);
    return wantarray ? %$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) server id is $sn.", 3);
  }
  if (! -d $dir) {
    $s->echo_msg("ERR: ($prg) could not find dir - $dir.", 0);
    return wantarray ? %$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) spec dir is $dir.", 3);
  }
  if (! $mlc || $mlc =~ /^\s*$/) {
    $s->echo_msg("ERR: ($prg) mdr_ldr_cfg is not defined in the init file.", 0);
    return wantarray ? %$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) mdr_ldr_cfg file is $dir.", 3);
  }
  my $fn = join $ds, $dir, $mlc;
  if (! -f $fn ) {
    $s->echo_msg("ERR: ($prg) $fn does not exist.", 0);
    return wantarray ? %$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) using $fn...", 3);
  }
  my $rp = $s->read_cfg_file($fn);

  # opendir DD, "$dir" or die "ERR: could not opendir - $dir: $!\n";
  # my @a = sort grep !/\.bak$/, (grep /\.xls$/i, readdir DD);
  # closedir DD;
  # get variables
  my $vr = {};
  for my $i (0..$#$rp) {
    my $k   = lc $rp->[$i][0];		# global V
    next if $k !~ /^V$/i;
    my $k1  = $rp->[$i][1];		# empty or study_id
    my $k2  = $rp->[$i][2]; 		# variable name
    my $v   = $rp->[$i][3]; 		# variable value
    next if $k2 =~ /^\s*$/; 		# skip if the variable name is empty
    $k = ($k1 =~ /^\s*$/) ? $k : $k1;
    $vr->{$k}{$k2} = $v;
  }

  # get study configuration
  $r->{v} = $vr->{v}		if exists $vr->{v};
  for my $i (0..$#$rp) {
    my $k   = $rp->[$i][0];				# study_id
    next if $k =~ /^V$/i;
    my $rdr = $rp->[$i][1];				# rel_dir
       $rdr =~ s/^\s*//g 	if $rdr;
       $rdr =~ s/\s*$//g	if $rdr;
    my $mfn = ($rp->[$i][2]) ? $rp->[$i][2] : '';	# meta file name
       $mfn =~ s/^\s*//g 	if $mfn;
       $mfn =~ s/\s*$//g	if $mfn;
    my $dfn = $rp->[$i][3];				# domain file or sheet name
       $dfn =~ s/^\s*//g 	if $dfn;
       $dfn =~ s/\s*$//g	if $dfn;
    my $vfn = $rp->[$i][4];				# variable file or sheet name
       $vfn =~ s/^\s*//g 	if $vfn;
       $vfn =~ s/\s*$//g	if $vfn;
    my $ofd = ($rp->[$i][5]) ? $rp->[$i][5] : '';	# output file dir
       $ofd =~ s/^\s*//g 	if $ofd;
       $ofd =~ s/\s*$//g	if $ofd;
    my $act = (exists $rp->[$i][6])?$rp->[$i][6]:'';	# DML type
    $r->{$k} = { rdr=>$rdr, mfn=>$mfn, dfn=>$dfn,vfn=>$vfn,ofd=>$ofd, dml=>$act};
    $r->{$k}{var} = $vr->{$k}	if exists $vr->{$k};
    for my $x (keys %{$vr->{v}}) {
      next if exists $r->{$k}{var}{$x};
      $r->{$k}{var}{$x} = $vr->{v}{$x};
    }
  };
  wantarray ? %$r : $r;
}


=head2 ld_mdrstd($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:

Variables used or routines called:

  None

Return: $pr will contain the parameters adn output from running the PL/SQL.

=cut


sub ld_mdrstd {
  my ($s, $q, $ar) = @_;

  my $prg = 'TaskLoads::ld_mdrstd';
  # 0. prepare parameters and check parameters
  $s->echo_msg(" 0. running $prg...", 1);
  my ($sid, $jid, $hid) = ();
  $sid = $ar->{study_id} 	if exists $ar->{study_id}
         && ($ar->{study_id} || $ar->{study_id} == 0);
  $jid = $ar->{job_id}  	if exists $ar->{job_id}
         && ($ar->{job_id} || $ar->{job_id} == 0);
  $hid = $ar->{hjob_id}  	if exists $ar->{hjob_id}
         && ($ar->{hjob_id} || $ar->{hjob_id} == 0);

  if ($sid != 0 && !$sid) {
    $s->echo_msg("ERR: ($prg) Study ID is required.", 0); return;
  }

  my $ds = ($^O =~ /MSWin/i) ? '\\' : '/';
  my $pid	= $ar->{pid};				# parent id
  my $sn 	= $ar->{sid}; 				# server id
  my $ad 	= eval $s->set_param('all_dir', $ar); 	# all dir array

  my $dir 	= $ad->{$sn}{mdr};			# mdr/map dir
  #  my $sqlout	= $ad->{$sn}{sqlout};			# sql output dir
  #  my $odr	= "$sqlout$ds$sn";
  $s->echo_msg("INFO: ($prg) dir=$dir",1);
  croak "ERR: ($prg) could not find dir - $dir." if ! -d $dir;

  # 1. get cfg information
  $s->echo_msg(" 1. get cfg info for study $sid...", 1);

  my $rp = $s->get_ldrcfg($ar);
  croak("ERR: ($prg) loader cfg is not defined.") if ! %$rp;
  croak("ERR: ($prg) loader cfg is not defined for study id - $sid.")
    if ! exists $rp->{$sid};

  my $vrs = 'dn_tab,vn_tab,sl_col,fk_col,fk_var,dn_key,vn_key';
  for my $k (split /,/, $vrs) {
    croak "ERR: ($prg) missing variable $k." if ! exists $rp->{$sid}{var}{$k};
  }
  my $rdr = join $ds, $dir, $rp->{$sid}{rdr};
  my $mfn = $rp->{$sid}{mfn};
     $mfn = ($mfn) ? (join $ds,$rdr,$mfn) : '';
  my $dfn = ($mfn) ? $rp->{$sid}{dfn} : (join $ds, $rdr,$rp->{$sid}{dfn});
  my $vfn = ($mfn) ? $rp->{$sid}{vfn} : (join $ds, $rdr,$rp->{$sid}{vfn});
  my $sdr = strftime "%Y$ds%m$ds%d", localtime;
  my $ofd = join $ds, $dir, $rp->{$sid}{ofd}, $sdr;

  my $dml_type = $rp->{$sid}{dml};
     $dml_type = ($dml_type) ? $dml_type : 'A';

  if (!-d $rdr) {
      croak "ERR: ($prg) could not find - $rdr<br>\n";
  }
  if (!-d $ofd) {
      $s->echo_msg("INFO: ($prg) make dir - $ofd.", 2);
      eval { mkpath($ofd,0,0777) };
      # mkdir $ofd;
      croak "ERR: ($prg) could not mkdir - $ofd: $!: $@<br>\n" if ($@);
      system("chmod -R ugo+w $ofd") 		if ($^O !~ /^MSWin/i); 	# non window
  }

  if ($mfn && ! -f $mfn) {
    croak "ERR: ($prg) could not find mfn file - $mfn";
  }
  $s->echo_msg("INFO: ($prg) RDR=$rdr",1);
  $s->echo_msg("INFO: ($prg) OFD=$ofd",1);
  $s->echo_msg("INFO: ($prg) MFN=$mfn",1);


  # 2. read the XLS file
  $s->echo_msg(" 2. read configuration files...", 1);
  my ($dr, $vr) = ();
  if ($mfn) {
    my $n1 = $rp->{$sid}{dfn};
    my $n2 = $rp->{$sid}{vfn};
    $s->echo_msg("INFO: MFN - $mfn ($n1,$n2).", 1);
    $dr  = $s->read_xls($mfn, $n1);
    $vr  = $s->read_xls($mfn, $n2);
  } else {
    $s->echo_msg("INFO: DFN - $dfn.", 1);
    $dr  = $s->read_cfg_file($dfn,'A',',');
    $s->echo_msg("INFO: vFN - $vfn.", 1);
    $vr  = $s->read_cfg_file($vfn,'A',',');
  }

# $s->disp_param($dr);
# $s->disp_param($vr);

  $s->echo_msg("INFO: ($prg) no of records for domain: $#$dr", 1);
  $s->echo_msg("INFO: ($prg) no of records for variable: $#$vr", 1);

  $s->echo_msg($dr, 5);
  $s->echo_msg($vr, 5);

  # 3. build SQL statement for cc_domains
  $s->echo_msg(" 3. build sql statement for cc_domains...", 1);
  my $sql 	= [];		# sql array
  my $rf	= {};		# ref for ldr parameter
     $rf->{tbn} = $rp->{$sid}{var}{dn_tab};
     $rf->{kcn} = $rp->{$sid}{var}{dn_key};
     $rf->{scn} = $rp->{$sid}{var}{sl_col};
     $rf->{scv} = $sid;
     $rf->{act} = $rp->{$sid}{dml};

  $rf->{dn_fmt} = '';
  $rf->{del_ctb} = '';
  $rf->{del_ptb} = '';
  if ($rf->{act} =~ /^D/i) {
    # delete child table first
    my $ptb = $rp->{$sid}{var}{dn_tab};
    my $ctb = $rp->{$sid}{var}{vn_tab};
    my $fkc = $rp->{$sid}{var}{fk_col};
    my $fkn = $rp->{$sid}{var}{fk_var};
    my $scn = $rp->{$sid}{var}{sl_col};
    my $t  = "PROMPT Deleting $ctb with $scn = $sid...\n";
       $t .= "DELETE $ctb WHERE $fkc IN (\n";
       $t .= "  SELECT $fkc FROM $ptb WHERE $scn = $sid);\n";
       $t .= "commit;\n\n";
    $rf->{del_ctb} = $t;   
       $t  = "PROMPT Deleting $ptb with $scn = $sid...\n";
       $t .= "DELETE $ptb WHERE $scn = $sid;\ncommit;\n\n";
    $rf->{del_ptb} = $t;   
    # SELECT dn_id FROM cc_domain WHERE study_id = 1 and domain_name = 'AE'
    my $dn_fmt  = "(SELECT MAX($fkc) FROM $ptb WHERE ";
       $dn_fmt .= "$scn = $sid AND UPPER($fkn) = '%s')";
    $rf->{dn_fmt} = $dn_fmt; 
  }

  my $sq1 = $s->build_dml($dr, $rf, $ar);
  $s->echo_msg("INFO: number of SQL statements: $#$sq1",1);
  $s->echo_msg($rf->{c1_crf}, 3);
  $s->echo_msg("SQL: ($prg) @$sq1",5);

  # 4. build SQL statement for cc_variables
  $s->echo_msg(" 4. build sql statement for cc_variables...", 1);
     $rf->{tbn} = $rp->{$sid}{var}{vn_tab};
     $rf->{kcn} = $rp->{$sid}{var}{vn_key}; 
     $rf->{ptb} = $rp->{$sid}{var}{dn_tab};	# parent table name
     $rf->{fkn} = $rp->{$sid}{var}{fk_var};	# fk column name: domain_name
     $rf->{fkc} = $rp->{$sid}{var}{fk_col};	# fk column name: dn_id
  my $sq2 = $s->build_dml($vr, $rf, $ar);
  $s->echo_msg("INFO: number of SQL statements: $#$sq2",1);
  $s->echo_msg($rf->{c2_crf}, 3);
  $s->echo_msg("SQL: ($prg) @$sq2",5);

  # 5. output to file
  $s->echo_msg(" 5. output to files...", 1);

  my $rt  = ($rp->{$sid}{mfn}) ? $rp->{$sid}{mfn} : $rp->{$sid}{dfn};
     $rt  =~ s/\.\w*$//i;					# get root name
  my $f1n = $rp->{$sid}{dfn};
  my $f2n = $rp->{$sid}{vfn};

  my $dtm = strftime "%Y%m%d_%H%M%S", localtime;
  my $ot1 = "${rt}_${f1n}_$dtm.sql";			# parent output file name
  my $ot2 = "${rt}_${f2n}_$dtm.sql";			# child  output file name
  my $fn1 = join $ds, $ofd,$ot1; 			# output file full name
  my $fn2 = join $ds, $ofd,$ot2; 			# output file full name

  my $m1 = "File - $ot1 was written to $ofd";
  my $m2 = "File - $ot2 was written to $ofd";

  $s->echo_msg("INFO: writing $fn1 ...", 1);
  open FN, ">$fn1" or croak "ERR: could not write to $fn1: $!\n";
  for my $i (0..$#$sq1) {
    # print FN "PROMPT $i/$#$sql \n";
    print FN "$sq1->[$i]";
    print FN "commit;\n" if ($i && $i % 100 == 0);
  }
  #  print FN "exit\n";
  close FN;
  $s->echo_msg($m1, 1);

  $s->echo_msg("INFO: writing $fn2 ...", 1);
  open FN, ">$fn2" or croak "ERR: could not write to $fn2: $!\n";
  for my $i (0..$#$sq2) {
    # print FN "PROMPT $i/$#$sql \n";
    print FN "$sq2->[$i]";
    print FN "commit;\n" if ($i % 100 == 0);
  }
  #  print FN "exit\n";
  close FN;
  $s->echo_msg($m2, 1);
  
  # 6. run sql
  $s->echo_msg(" 6. run sql statements ...", 1);

  my $rr = [];
  push @$rr, "$m1\n";
  push @$rr, "$m2\n";
  $s->echo_msg("INFO: number of executions: " . ($#$rr+1),1);  
  $s->call_plsql($rr, $ar);

  # wantarray ? @$r : $r;
}


=head2 build_dml($rr, $rf, $ar)

Input variables:

  $rr	- array ([$i]{$k}) with new data
  $rf   - hash array with the following elements
    tbn - table name: 		cc_domains
    kcn - key column name: 	dn_id
    scn - select column name:	study_id
    scv - select column value: 1
    act - DML type: A-auto, D-delete, I-insert, U-update
  $ar   - hash array for system wide parameters
  
Variables used or routines called:

  None

Return: This procedure returns an array containing DML SQL statements and
populate the $rf with the following new elements:

  c1_crf  - column definition array [$i]{$k} for the table where $k=
            column_name,data_type,data_length
  c1_vars - a list of column names separated by comma in the table
  c2_crf  - column definition array [$i]{$k} for the new data where $k=
            column_name,data_type,data_length
  c2_vars - a list of column names separated by comma in the data

=cut


sub build_dml {
  my ($s, $rr, $rf, $ar) = @_;

  my $prg = 'TaskLoads::build_dml';
  my $tbn = $rf->{tbn};
  my $kcn = $rf->{kcn};
  my $act = $rf->{act}; $act =~ s/^\s*//; $act =~ s/\s*$//;
  my $scn = $rf->{scn};
  my $scv = $rf->{scv};

# $s->disp_param($rr); 

#  my $cns = lc $rf->{cns};
#  $rf->{list_cns} = $s->_list_cns($cns);


  # get column names for from the table
  my $whr  = " WHERE table_name = '" . uc($tbn) . "' ";
     $whr .= " ORDER BY column_id ";
  my $sel_cns  =  'column_name,data_type,data_length' ;
  my $c1 = $s->run_sqlcmd($ar, $sel_cns, 'user_tab_columns', $whr);
  for my $i (0..$#$c1) {$c1->[$i]{column_name} = lc $c1->[$i]{column_name};}
  my $c1_vars = $s->cvt_ar2list($c1);
  $rf->{c1_vars} = $c1_vars;
  $rf->{c1_crf}  = $c1;

  my $r1 = [];
  if ($act =~ /^(A|U)/i) {
    # get data from the table
    $whr  = " WHERE $scn = $scv ORDER BY $scn ";
    $r1 = $s->run_sqlcmd($ar, $c1_vars, $tbn, $whr);
  }

  # convert the new data set into the same format
  my ($r2, $c2)  = $s->cvt_ar2hr($rr, $rf->{c1_vars});
  my $c2_vars    = $s->cvt_ar2list($c2);
  $rf->{c2_vars} = $c2_vars;
  $rf->{c2_crf}  = $c2;


  # convert $r1 to hash hash array
  my $r3 = {};
  if (@{$rf->{c1_crf}} && exists $r1->[0]{$kcn}) {
    for my $i (0..$#$r1) {
      my $k = $r1->[$i]{$kcn}; 
      $r3->{$k} = $r1->[$i]; 
    }
  } 
  my $sql = [];
  my ($t,$i,$m) = ('',-1,'');
  if ($act =~ /^D/i) {
    if (exists $rf->{fkc} || exists $rf->{ptb}) {		# child table
        push @$sql, "/*\n $rf->{del_ctb}*/\n\n" if $rf->{del_ctb}; 
    } else { 
        push @$sql, $rf->{del_ctb} if $rf->{del_ctb}; 
        push @$sql, $rf->{del_ptb} if $rf->{del_ptb}; 
    } 
  }

  $t = '';
  for my $i (1..$#$r2) {  	# start with 1 since the first row is column names
    my $k = (exists $r2->[$i]{$kcn}) ? $r2->[$i]{$kcn} : '';
    $m  = "(" . (uc $act) . "):$k ";
    $m .= $r2->[$i]{$kcn}		if exists $r2->[$i]{$kcn};
    $m .= " $r2->[$i]{domain_name}"	if exists $r2->[$i]{domain_name};
    $m .= "." . $r2->[$i]{var_name}	if exists $r2->[$i]{var_name};

    if ($act =~ /^D/ || ! @{$rf->{c1_crf}}) {
      $t  = "PROMPT $i/$#$r2 - inserting $m...\n";
      $t .= $s->get_insert_val($r2->[$i], $rf);
    } else {
      if ($k) {		# record exists
        if ($act =~ /^I/) {
          $t  = "PROMPT $i/$#$r2 - record exists skipping $m...\n";
          next;
        }
        $rf->{kcv} = $k;
        $t  = "PROMPT $i/$#$r2 - updating $m...\n";
        $t .= $s->get_update_val($r2->[$i], $rf, $r3->{$k});
      } else {
        if ($act =~ /^U/) {
          $t  = "PROMPT $i/$#$r2 - record does not exist skipping $m...\n";
          next;
        } else {
          $t  = "PROMPT $i/$#$r2 - inserting $m...\n";
          $t .= $s->get_insert_val($r2->[$i], $rf);
        }
      }
    }
    push @$sql, $t;
  }
  $s->echo_msg("SQL: ($prg) $sql",5);

  wantarray ? @$sql : $sql;
}

sub get_insert_val {
  my ($s, $hr, $rf) = @_;

  my $prg = 'TaskLoads::get_insert_val';
  if (! exists $rf->{c1_vars} && ! exists $rf->{c2_vars}) {
    $s->echo_msg("ERR: ($prg) c1_vars and c2_vars are missing",0);
    return '';
  }

  if (! exists $rf->{c1_crf} && ! exists $rf->{c2_crf}) {
    $s->echo_msg("ERR: ($prg) c1_crf and c2_crf are missing",0);
    return '';
  }

  my $tab = $rf->{tbn};
  my $cns = (exists $rf->{c1_vars}) ? $rf->{c1_vars} : $rf->{c2_vars};
     $cns = $s->fmt_list2sel($cns);
  my $seq = $rf->{tbn} . "_seq.nextval";
  my $cr  = (exists $rf->{c1_crf}) ? $rf->{c1_crf} : $rf->{c2_crf};

  my $dn_id  = '';
  my $dn_fmt = $rf->{dn_fmt};   

  my $t = '';
  foreach my $j (0..$#$cr) {
    my $k = lc $cr->[$j]{column_name};
    my $p = $cr->[$j]{data_type};
    my $v = (exists $hr->{$k}) ? $hr->{$k} : '';
       $v =~ s/\s*$//g 		if $v;		# remove ending spaces
       $v =~ s/'/''/g  		if $v;		# double quote
       $v =~ s/^\s*\n+//mg 	if $v;		# remove multiple line breaks
       $v =~ s/\&/and/g		if $v;		# replace & with and
       $v =~ s/^\s*$//g 	if $v;		# remove all spaces
    $t .= ($t) ? '    , ' : '      ';
    if ($k =~ /^$rf->{kcn}/i) {			# dn_id/var_id
        $t .= "$seq\n";
    } elsif (exists $rf->{fkc} && $rf->{fkc} && $k =~ /^$rf->{fkc}/i) {	# dn_id
      if (exists $rf->{ptb}) {			# it is a child table: cc_variables
        my $fk = $rf->{fkn};
        $dn_id = sprintf $dn_fmt, uc $hr->{$fk};
        $t .= ($v) ? "$v\n" : "$dn_id\n";
      } else {
        $t .= "$seq\n";
      }
    } elsif ($k =~ /^$rf->{scn}/i) { 		# study_id
      $t .= ($v) ? "$v\n" : "$rf->{scv}\n";
    } elsif ($k =~ /^db_user/i) {
      $t .= ($v) ? "'$v'\n" : "USER\n";
    } elsif ($k =~ /^os_user/i) {
      $t .= ($v) ? "'$v'\n" : "cc_context_pkg.get_os_user\n";
    } elsif ($k =~ /^app_user/i) {
      $t .= ($v) ? "'$v'\n" : "cc_context_pkg.get_app_user\n";
    } else {
      if ($p =~ /^date/i) {
        $t .= "sysdate\n";
      } elsif ($p =~ /^(num|int|float)/i) {
        $t .= (("$v" eq "0")||($v && $v =~ /^[\d\.]+$/)) ? "$v\n" : "null\n";
      } else {
        $t .= ($v) ? "'$v'\n" : "null\n";
      }
    }
  }
  # $t =~ s/^(\s*),/$1 /;
  $t = "INSERT INTO $tab (\n$cns  ) VALUES (\n$t  );\n";
  return $t;
}


sub get_update_val {
  my ($s, $hr, $rf, $h2) = @_;

  my $cr  = (exists $rf->{c1_crf}) ? $rf->{c1_crf} : $rf->{c2_crf};
  my $seq = $rf->{tbn} . "_seq.nextval";

  my $dn_id  = '';
  my $dn_fmt = $rf->{dn_fmt};   

  my $t = '';
  foreach my $j (0..$#$cr) {
    my $k = lc $cr->[$j]{column_name};
    my $p = $cr->[$j]{data_type};
    my $v = (exists $hr->{$k}) ? $hr->{$k} : '';
       $v =~ s/\s*$//g 		if $v;		# remove ending spaces
       $v =~ s/'/''/g  		if $v;		# double quote
       $v =~ s/^\s*\n+//mg 	if $v;		# remove multiple line breaks
       $v =~ s/\&/and/g		if $v;		# replace & with and
       $v =~ s/^\s*$//g 	if $v;		# remove all spaces
    my $v2 = $h2->{$k};
    next if $v =~ /^\s*$/; 			# skip empty string
    next if (lc $v) eq (lc $v2); 	# skip if the value has not changed
    next if $k eq $rf->{kcn}; 		# skip the key column: dn_id/var_id

    $v = uc $v; 			# convert to upper case
    if (exists $rf->{fkc} && $rf->{fkc} && $k =~ /^$rf->{fkc}/i) {	# dn_id
      if (exists $rf->{ptb}) {			# it is a child table: cc_variables
        my $fk = $rf->{fkn};
        $dn_id = sprintf $dn_fmt, uc $hr->{$fk};
        $t .= ($v) ? "$v\n" : "$dn_id\n";
      } else {
        $t .= "$seq\n";
      }
    } elsif ($k =~ /^$rf->{scn}/i) { 	#
      $t .= ($v) ? "$v\n" : "$rf->{scv}\n";
    } elsif ($k =~ /^db_user/i) {
      $t .= ($v) ? "'$v'\n" : "    , USER\n";
    } elsif ($k =~ /^os_user/i) {
      $t .= ($v) ? "'$v'\n" : "cc_context_pkg.get_os_user\n";
    } elsif ($k =~ /^app_user/i) {
      $t .= ($v) ? "'$v'\n" : "cc_context_pkg.get_app_user\n";
    } elsif ($k =~ /date$/i) {
      $t .= "sysdate\n";
    } else {
      if ($p =~ /^date/i) {
        $t .= "sysdate\n";
      } elsif ($p =~ /^(num|int|float)/i) {
        $t .= ($v==0||($v && $v =~ /^[\d\.]+$/)) ? "$v\n" : "null\n";
      } else {
        $t .= ($v) ? "'$v'\n" : "null\n";
      }
    }
  }
  # $t =~ s/^(\s*),/$1 /;
  $t = "UPDATE $rf->{tbn} $t WHERE $rf->{kcn} = $rf->{kcv};\n";
  
  return $t;
}


=head2 cvt_ar2list($cr)

Input variables:

  $cr	- array ref containing column definitions ([$i]{$k}) where $k is
          column_name, data_type, and data_length

Variables used or routines called:

  None

Return: a list containing column names separated by comma

=cut

sub cvt_ar2list {
  my ($s, $cr) = @_;

  my $t = '';
  for my $i (0..$#$cr) {
    my $k = lc $cr->[$i]{column_name};
       $k =~ s/^\s*//; $k =~ s/\s*$//;
    $t .= ($t) ? ",$k" : $k;
  }
  return $t;
}

=head2 fmt_list2sel ($cns)

Input variables:

  $cns	- column names separated by comma

Variables used or routines called:

  None

Return: a formated list to be used in SELECT statement.

=cut

sub fmt_list2sel {
  my ($s, $cns) = @_;
  my $t = '';
  foreach my $k (split /,/, $cns) {
    $t .= ($t) ? "    , $k\n" : "      $k\n";
  }
  return $t;
}


=head2 cvt_ar2hr($ar, $vars)

Input variables:

  $ar	- array ref containing two dimensional data elements in an array
  $vars - variable names sparated by comma

Variables used or routines called:

  None

Return: an array with hash elements $r->[$i]{$k}.

=cut

sub cvt_ar2hr {
  my ($s, $rr, $vars) = @_;

  my $r 	= [];		# record array
  my $c 	= [];		# column array

  # get column names
  my $cns = {};
  if ($vars) {
    foreach my $k (split /,/, lc $vars) {  $cns->{$k} = 1;   }
  }
  # the first row contains the column names
  for my $j (0..$#{$rr->[0]}) {
    my $k = lc $rr->[0][$j];
       $k =~ s/^\s*//; $k =~ s/\s*$//; $k =~ s/ /_/g;
    if (exists $cns->{$k}) {
      $r->[0]{$k} = $k;
    } else {
      $s->echo_msg("  Col: $k - does not exist in table.", 2) if $vars;
    }
    $c->[$j]{column_name} = $k;
  }
  for my $i (1..$#$rr) {
    for my $j (0..$#{$rr->[$i]}) {
      my $k = lc $c->[$j]{column_name};
      my $v = $rr->[$i][$j];
      $r->[$i]{$k} = $v;
    }
  }
  # get column type
  for my $j (0..$#$c) {
    my $cnt = -1;
    my $len = -1;
    for my $i (1..$#$rr) {
      my $k = lc $c->[$j]{column_name};
      my $v = $rr->[$i][$j];
      if ($v =~ /^[\d\.]+$/) { ++$cnt; }
      $len = (length($v) > $len) ? length($v) : $len;
    }  
    $c->[$j]{data_type}   = ($cnt == $#$rr) ? 'number' : 'varchar2';
    $c->[$j]{data_length} = ($len) ? $len : 1;
  }
  return ($r, $c);
}


=head2 coding

sub prt_txt_file {
    my ($s, $fn,$ar) = @_;
    my ($fname, $path, $sfx) = fileparse($fn,qr{\..*});
    my $t1 = "<center><b>$fname$sfx</b></center>\n<hr>\n<pre>\n";
    my $typ = 
    my $w  = 
    my $st = 
    my $t = "";
    my $n = $w;
    open FILE, "<$fn" or die "ERR: could not open $fn: $!\n";
    while (<FILE>) {
        s/</\&lt;/g; s/>/\&gt;/g;
        s//^L/g;    # change the non-printable char to printable char
        if ($st) { 
          s/($st)/<font color=red>$1<\/font>/ig; 
        }
        my ($tt, $i) = ($_, -1); 
        if (length($tt) < $n || !$w ) {
            $t .= $tt; next;
        }
        while (length($tt) >= $n) {
            ++$i;
            if ($i) {     # the second line
                $t .= " "x4 . substr($tt, 0, $n) . "\n";
            } else {      # first line
                $t .= substr($tt, 0, $n) . "\n";
            }
            $tt = substr($tt, $n);
        }
        $t .= " "x4 . $tt;
    }
    close FILE;
    return $t if $typ; 
    print "$t1$t</pre><br>\n";
}

=cut

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version was started on 09/28/2011.

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

1;
