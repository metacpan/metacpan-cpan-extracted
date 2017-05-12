package CGI::AppBuilder::PLSQL;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Path; 
use Net::Rexec 'rexec';

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(	exec_plsql call_plsql read_plsql _parseline2 
 			expand_vars expand_code
                   );
our %EXPORT_TAGS = (
    plsql => [qw(exec_plsql call_plsql read_plsql)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::PLSQL - Oracle PL/SQL Procedures

=head1 SYNOPSIS

  use CGI::AppBuilder::PLSQL;

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

=head2 exec_plsql($q,$ar)

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
  	HA_*		: hash array

Variables used or routines called:

  None

How to use:

First define the parameters in the initial file or define all the parameters
in a hash array reference as $ar->{$p} where $p are
  #
  # parameters in initial file  
  pid		= ckpt
  task		= task2
  target	= owb1
  args		= val1:val2
  task_fn	= ora_jobs.txt
  outdir	= /opt/www/logs
  excl_callsql	= run_xmlrpt|run_genrpt		# tasks excluded from calling call_plsql
  svr_conn	= { 	# server connection 
    usr => 'usr_name',
    pwd => 'security',
    svr => 'svr_name',
    orahome => '/opt/app/oracle/product/10.2.0/db_1',
    }
  db_conn = { 
    tgt1 => 'system/pwd@dbl_1',
    tgt2 => 'system/pwd@dbl_2',
    }
  task_conn = {
    tgt1   => { task1 => 'owb_rep2/pwd@owb1', },
    tgt2   => { },
  }
  out_dir = {		# overwrite general out_dir
    ckpt 	=> 'd:/www/logs/ckpt/rpts',
    owb1	=> '/opt/www/logs/owb1/rpts',
    }
  arg_required = {
    task1	=> 'obj_name',
    }
  svr_allowed = {
    task1  => {cdx1=>1},
    }
  task_sql = {
    task5  => 'chkts.sql',
    task8  => 'owb/owbcollect_exit.sql',
    }

    
  #
  # Tasks defined in task file (task_fn)    
  task1 = 		# staigth SQL statement example
    ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';
    SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;
    PROMPT <b> Get instance status </b>;
    PROMPT <hr>;  
    COL host_name    	FOR a25; 
    COL up_days		FOR 9999.99;
    SELECT a.*, sysdate-startup_time as up_days FROM v\$instance a;
  task2 = 		#     

  my ($q, $ar, $ar_log) = $self->start_app($0, \@ARGV);
  or
  my $ar = $self->read_init_file('/tmp/my_init.cfg');
  $self->exec_plsql($q, $ar); 

You can use variables in the definition file. We have provided a list of 
pre-defined variables such as 

    $a0~$a9	= arguments in sel_sn2 separated by colon (:)
    $sid	= <db_id_or_svr_id> 	($sn)
    $dtm	= <date_and_time> 	("%Y%m%d_%H%M%S")
    $dt		= <date> 		("%Y%m%d")
    $tm		= <time> 		("%H%M%S")
    $y4		= <four_digit_year> 	("%Y")
    $mm		= <month> 		("%m")
    $dd		= <date> 		("%d")
    $hh		= <hour> 		("%H")
    $mi		= <minute> 		("%M")
    $ss		= <second> 		("%S")

Return: $pr will contain the parameters adn output from running the PL/SQL.

  plsql_out 	- output from running the PL/SQL
  is_callsql	- whether to run call_plsql

=cut

sub exec_plsql {
    my ($s, $q, $ar) = @_;

    # print $s->disp_form($q, $ar); 
    print $s->disp_header($q, $ar); 

  my @c0 = caller(0); my @c1 = caller(1);
  my $cls = (exists $c1[3]) ? $c1[3] : ''; 
  my $prg = "$cls [$c0[2]] -> $c0[3]"; 
  
    # 1. check required parameters
    $s->echo_msg("1. checking required parameters...", 2);
    my $vs = 'pid,task,task_fn,svr_conn,db_conn';
    foreach my $t (split /,/, $vs) {
      if (! exists $ar->{$t}) {
        $s->echo_msg("ERR($prg): Parameter $t does not exist.",0); return;
      }
    }
    my $pr	= $s->def_inputvars($ar);
    my $sn 	= $pr->{sid}; 				# sel_sn1 or target 
    my $pid 	= $ar->{pid};				# project id
    my $tsk	= lc $ar->{task};			# task name
    my $ds	= $pr->{ds};				# directory separator
    my ($m)	= ();
    my $avs = 'svr_conn,db_conn,task_conn,out_dir,arg_required,svr_allowed';
      $avs .= ',task_sql';
    foreach my $t (split /,/, $avs) {
      if ($t eq $tsk) {
        $m = "ERR($prg): you could not use a preserved word to name your ";
        $m .= "task - $tsk"; 
        $s->echo_msg($m, 0); return;
      }
    }
   
    # 2. read the task files
    $s->echo_msg("2. reading task file...", 2);
    my ($fn,$tsk_txt,$tsk_fn,$tsq) = ();
    my $p   = {}; 
    my $tfn = $s->set_param('task_fn', $ar);	# task file name:jp2.txt
    my $ifn = $s->set_param('ifn',     $ar);	# parent init file name
    my $tmp = $ifn;	$tmp =~ s/\.(\w+)//;
    my $tf2 = join $ds, $tmp, $pid, "$tsk.txt"; # task file name: jp2/ckpt/tsk1.txt
    $ar->{ifn_dir} = $tmp; 			# init file dir
    if (-f $tfn) {
      $s->echo_msg("INFO: ($prg) reading $tfn...", 3);
      $p 	= $s->read_init_file($tfn);
      $tsk_txt	= (exists $p->{$tsk}) ? $p->{$tsk} : ""; 
      $s->echo_msg("INFO: ($prg) did not find $tsk in $tfn.", 3) if !$tsk_txt;
    } else {
      $s->echo_msg("INFO: ($prg) did not $tfn.", 3);
    }
    if (!$tsk_txt) {
      if (-f $tf2) { 
        $s->echo_msg("INFO: ($prg) reading $tf2...", 3); 
        $p	= $s->read_init_file($tf2); 
        $tsk_txt= (exists $p->{$tsk}) ? $p->{$tsk} : "";
        $s->echo_msg("INFO: ($prg) did not find $tsk in $tf2.", 3) if !$tsk_txt;
      } else {
        $s->echo_msg("INFO: ($prg) did not find $tf2.", 3);
      }
    } 
    if (!$tsk_txt) {					# look it in task_sql
      if (! exists $ar->{task_sql}) {
        $s->echo_msg("ERR: ($prg) no task sql is defined for $tsk.", 0); return;
      } 
      $tsq = eval $ar->{task_sql}; 
      if (! exists $tsq->{$tsk}) {
        $s->echo_msg("ERR: ($prg) no task is defined in task sql for $tsk.", 0); return;
      } 
      $tsk_fn = $tsq->{$tsk}; 
      $p->{is_tasksql} = 1;				# in sql file
    } else {
      $p->{is_tasksql} = 0;				# in sql code
    } 

    # 3. explode parameters
    $s->echo_msg("3. exploding parameters...", 2);
    foreach my $t (split /,/, $avs) {
      $ar->{$t} = $s->expand_vars($ar->{$t}, $pr);
    }
    # my $opf = eval $s->set_param('opf_labels', $ar);	# DB names
    my $scn = eval $s->set_param('svr_conn', $ar);  	# Server connections
    my $dbc = eval $s->set_param('db_conn', $ar);   	# DB connections
    my $amr = eval $s->set_param('arg_required', $ar);	# ARG is required

#    my $tcn = {};   					# Task connections
#       $tcn = eval $ar->{task_conn} 
#              if exists $ar->{task_conn} && $ar->{task_conn};
#    my $odr = {}; 				 	# Out dir
#       $odr = eval $s->set_param('out_dir', $ar)
#              if exists $ar->{out_dir} && $ar->{out_dir};
# $s->disp_param($ar);
# print "AMR: $amr<br>\n";    
# print "ODR: $odr, $odr->{$sn}{db}, $odr->{$sn}{web}<br>\n";    
# print "TCN: $tcn<br>\n";    
# print "DBC: $dbc<br>\n";    
    # set outdir 
#    if (exists $odr->{$sn}) {
#      $pr->{db_outdir}  = $odr->{$sn}{db}; 
#      $pr->{web_outdir} = $odr->{$sn}{web}; 
#    } else {
#      $pr->{db_outdir}  = $ar->{outdir} if exists $ar->{outdir}; 
#      $pr->{web_outdir} = $ar->{outdir} if exists $ar->{outdir}; 
#    }
    if (! exists $pr->{web_outdir}) {
      $s->echo_msg("ERR: out_dir was not defined.", 0);  return; 
    }
#    $pr->{tgt_dir} = join $ds, $pr->{web_outdir}, $sn, $tsk;
#    $pr->{log_dir} = join $ds, $pr->{tgt_dir}, $pr->{y4}, $pr->{mm};
#    $pr->{sql_fn}  = join $ds, $pr->{log_dir}, "s$pr->{dtm}.sql"; 
    # set db connection
    my $cs = $pr->{cs}; 
    if (!$cs) {
      $s->echo_msg("ERR: ($prg) db connection was not defined.", 0); return; 
    } 
    my $cr = {};					# code array ref
    if ($ar->{preload_code} && !$p->{is_tasksql}) {
      $cr->{plsql_dir} = $ar->{plsql_dir}  if exists $ar->{plsql_dir}; 
      $cr->{plsql_dir} = $ar->{ifn_dir}    if !$cr->{plsql_dir};
      my $pdr = $cr->{plsql_dir}; 
      $s->echo_msg("INFO: ($prg) loading codes from $pdr...", 3);
      if (-d $pdr) {
        opendir DD, "$pdr" or croak "ERR: could not opendir - $pdr: $!\n";
        my @a = sort grep !/\.bak$/, (grep !/^\./, readdir DD);
        # map {  $s->read_plsql("$pdr/$_",$cr); } sort grep !/\.bak$/, (grep !/^\./, readdir DD);
        closedir DD; 
        for my $x (0..$#a) { my $f = $a[$x]; 
        $s->read_plsql("$pdr/$f",$cr); }
        $s->echo_msg($cr,9); 
      } else {
        $s->echo_msg("ERR: ($prg) could not find plsql code dir - $pdr", 0);
      }
    }
    ($pr->{mtr_sch}) = ($cs =~ /^(\w+)\//); 		# db schema 
    if (!$p->{is_tasksql}) {
      #           $txt =~ s/,\s*/,\n/g;        
      $tsk_txt =~ s/;\s*/;\n/g;				# add line break back
      $tsk_txt =~ s/(declare|begin)/$1\n/ig; 		# add line break
      $tsk_txt = $s->expand_vars($tsk_txt, $pr);	# expand param variables
      $tsk_txt = $s->expand_vars($tsk_txt, $ar);	# expand param variables      
      $tsk_txt =~ s/(\'?\$a\d+\'?)/null/g;		# nullify the missing $a1,$a2,
      $tsk_txt =~ s{\/\;\s*}{\/\n}g; 			# remove ; for /;
      $tsk_txt =~ s/(\s*,\s*\w+\s*=>)/\n  $1/ig;	# add line break
      $tsk_txt =~ s/\s+(where|order by|group by)/\n  $1/ig;	# add line break
      $tsk_txt =~ s/(union all|union)/\n$1\n/ig;	# add line break
      $s->echo_msg("TXT: <pre>\n$tsk_txt\n</pre>",3);
    }

    # 4. set output directories
    $s->echo_msg("4. setting output directories...", 2);
    # mkdir $pr->{out_dir}, 0777 if (! -d $pr->{out_dir});
    # mkdir $pr->{tgt_dir}, 0777 if (! -d $pr->{tgt_dir});
    if (! -d $pr->{log_dir}) { 
      eval { mkpath($pr->{log_dir},0,0777) };
      croak "ERR: could not mkdir - $pr->{log_dir}: $!: $@<br>\n" if ($@);
      if ($^O !~ /^MSWin/i) { 				# non window
        system("chmod -R ugo+w $pr->{log_dir}"); 
      }
    } 
    my $radr = $ENV{REMOTE_ADDR}; $radr =~ s/\./_/g;
    my $tmpd = join $ds,$pr->{web_outdir},$sn,$radr,$pr->{y4},$pr->{mm},$pr->{dd};
    if (! -d $tmpd && ! $pr->{is_tasksql}) {
      eval { mkpath($tmpd,0,0777) };
      croak "ERR: could not mkdir - $tmpd: $!: $@<br>\n" if ($@);
      if ($^O !~ /^MSWin/i) { 				# non window
        system("chmod -R ugo+w $tmpd"); 
      }
    } 
    my $tpf1 = join $ds, $tmpd, "${tsk}_$pr->{tm}.sql"; 

    # 5. compose command
    $s->echo_msg("5. composing commands...", 2);
    my $rc  = {'0'=>'OK', '1'=>'Command is not invoked', '2'=>'Failed'};
    my ($svr,$usr,$pwd,$ohm) = ();
    my $vhm = 'ORACLE_HOME'; 
       $ohm = $ENV{$vhm} 	if exists $ENV{$vhm} && $ENV{$vhm}; 
       $ohm = $scn->{orahome}	if !$ohm && exists $scn->{orahome}; 
       $svr = $scn->{svr}	if exists $scn->{svr};
       $usr = $scn->{usr}	if exists $scn->{usr};
       $pwd = $scn->{pwd}	if exists $scn->{pwd};
    # my ($svr,$usr,$pwd,$ohm) = 
    #    ($scn->{svr},$scn->{usr},$scn->{pwd},$scn->{orahome});

    my $cfn  = join $ds, $ohm, 'bin', 'sqlplus';	# command file name
       $cfn .= ".exe" 	if ($^O =~ /^MSWin/i); 
    $s->echo_msg("INFO: ($prg) CFN set to $cfn", 2);        
    # if (! -f $cfn) {
    #   $s->echo_msg("ERR: could not find - $cfn", 0); return; 
    # } 
    $pr->{sql_cfn} = $cfn;				# command file name
    $pr->{sql_cs}  = $cs;				# connection string
    # keep the variables 
    $ar->{sql_cfn} = $cfn; 				# command file name
    $ar->{sql_cs}  = $cs; 				# connection string
    $s->echo_msg($pr, 4);
    my ($r1, @a) = ();
    if ($^O !~ /^MSWin/i) { 				# non window
       ($r1, @a) = rexec($svr, 'ls -l $cfn', $usr, $pwd);
       $s->echo_msg("INFO: ($prg) R1: $r1 - $rc->{$r1}", 3); $s->echo_msg(\@a,3);
      if ($r1 > 0) {
          $s->echo_msg("ERR: ($prg) could not run command - $cfn: $!.", 0);
          return;
      }
    }
    my $cmd;
    if ($^O !~ /^MSWin/i) { 			# non window
       $cmd = "ORACLE_HOME=$ohm;\nexport ORACLE_HOME;\n";
    } else {					# window
       $cmd = '';
    }
    if ($p->{is_tasksql}) {
      $cmd .= "$cfn -S $cs \@$tsk_fn";
    } else {
        $s->echo_msg("TXT: <pre>\n$tsk_txt\n</pre>",3);
        $s->echo_msg("INFO: ($prg) Writing SQL to $tpf1...",2);
        open  TMPSQL,">$tpf1" or carp "ERR: could not write to $tpf1: $!\n";
        print TMPSQL "$tsk_txt\nexit;\n";
        close TMPSQL; 
        if ($cr) { 
          $s->expand_code($tpf1, $cr);		# expand code variables              
          $s->expand_code($tpf1, $cr);		# expand code variables 
          $s->expand_code($tpf1, $cr);		# expand code variables 
        } 
        $cmd .= "$cfn -S $cs \@$tpf1"; 
        croak "ERR: did not find sql file - $tpf1<br>\n" if ! -f $tpf1; 
    } 
    my $cmd2 = $cmd;  $cmd2 =~ s/\</&lt;/g;
    $s->echo_msg("CMD: <pre>\n$cmd2\n</pre>",2);


    # 6. Execute the command
    $s->echo_msg("6. executing the command...", 2); 
    # $s->echo_msg("  $p->{$tsk}",2);
#    if ($^O !~ /^MSWin/i) { 			# non window
#      ($r1, @a) = rexec($svr, $cmd, $usr, $pwd);
#    } else { 
      $s->echo_msg("INFO: ($prg) set ORACLE_HOME=$ohm and PATH=$ohm/bin",3); 
      $ENV{ORACLE_HOME}=$ohm;
      $ENV{PATH}="$ohm/bin"; 
      open SQL, "$cmd|" or croak "ERR: could not run $cmd: $!<br>\n";
      @a = <SQL>;     close SQL;
#    }
    $pr->{plsql_out}  = \@a; 
    $pr->{is_callsql} = 1;
    $pr->{is_callsql} = 0 if (!$pr || ! exists $pr->{a0});
    $pr->{is_callsql} = 0 if (exists $ar->{excl_callsql} && 
      $tsk =~ /^($ar->{excl_callsql})/i);
    $s->echo_msg("INFO: ($prg) output lines: $#a.", 3); 
    if ($s->debug > 4) { for my $i (0..$#a) { print "$i: $a[$i]<br>\n"; } }
    # print "<pre><tt>\n@a\n</tt></pre>\n";
    
    # get data records in the display and assign them into $ar
    my $rr = $s->parse_record2(\@a, undef, '==',',');
    foreach my $k (keys %{$rr->[0]}) { $ar->{$k} = $rr->[0]{$k}; } 
    # $s->set_cookies($q, $ar) if ($tsk =~ /^run_login/i);
    $ar->{_sql_output} = \@a; 
    if ($tsk && $tsk =~ /^(run_login|run_logout)/i) {
      my $u_vs = 'user_sid,user_uid,user_tmo'; 
      my ($u_sid,$u_uid,$u_tmo) = $s->get_params($u_vs,$ar); 
      $u_sid = ($u_sid) ? $u_sid : '';
      $u_uid = ($u_uid) ? $u_uid : '';
      $u_tmo = ($u_tmo) ? $u_tmo : '';
      $ar->{guid} = "$u_sid:$u_uid:$u_tmo"; 
      $s->disp_index($q, $ar);
    } else { 
      print "<pre>\n@a\n</pre>\n";
    } 

    # $s->echo_msg(\@a,0);

    wantarray ? %$pr : $pr; 
    
    # $s->call_plsql(\@a, $ar);

}

sub call_plsql {
    my ($s, $rr, $ar) = @_;
    
  my @c0 = caller(0); my @c1 = caller(1);
  my $cls = (exists $c1[3]) ? $c1[3] : ''; 
  my $prg = "$cls [$c0[2]] -> $c0[3]"; 

    my $vs = 'dir_sep,sql_cfn,sql_cs';
    my ($ds,$cfn,$cs) = $s->get_params($vs, $ar);
    my $scn = eval $s->set_param('svr_conn', $ar);  	# Server connections
    my $dbc = eval $s->set_param('db_conn', $ar);     # DB connections
    my ($svr,$usr,$pwd,$ohm) = ();
      $ohm = $ar->{ohm} 	if exists $ar->{ohm}; 
      $ohm = $scn->{orahome}	if !$ohm && exists $scn->{orahome}; 
#    my $vhm = 'ORACLE_HOME'; 
#       $ohm = $ENV{$vhm} 	if exists $ENV{$vhm} && $ENV{$vhm}; 
       $svr = $scn->{svr}	if exists $scn->{svr};
       $usr = $scn->{usr}	if exists $scn->{usr};
       $pwd = $scn->{pwd}	if exists $scn->{pwd};
    
    my $sn = $ar->{sid}; 
    $sn = $ar->{sel_sn1}	if !$sn; 
    $ds = '/'  			if !$ds;
    $cs = $dbc->{$sn}		if !$cs; 
    if (!$cfn) { 
      if ($^O !~ /^MSWin/i) { 
        $cfn = join $ds, $ohm, 'bin', 'sqlplus'; 
      } else {
        $cfn = join $ds, $ohm, 'bin', 'sqlplus.exe'; 
      }
    }
    if (! -f $cfn) {
      $s->echo_msg("ERR: ($prg) could not find sqlplus program - $cfn.", 0);
      return;
    }
    if (!$cs) {
      $s->echo_msg("ERR: ($prg) no db connect string.", 0);
      return;
    }
    $s->echo_msg("INFO: ($prg) CFN set to $cfn.", 2); 
    #
    # get a list of PL/SQL files
    my ($f1, $d1, $r1) = ("","","");     # PL/SQL file name and folder name
    # File - vw_acorda_stg_co.sql was written to /opt/ora/ufd/owbprod.
    # N:\Client\owb_dir\owbprod
    my @a = (); my @b = ();
    my $re = qr/[\w\/\.\:\\\-\[\]\$]+/; 
    foreach my $i (0..$#$rr) {
        my $rec = $rr->[$i];
        if ($rec =~ m/^\s*File was spooled to ($re)/) {
            push @b, $1;
        } elsif ($rec =~ m/^\s*File - ([\w\.\-\$]+)\s* was written to ($re)/) {
            ($f1, $d1) = ($1, $2); push @b, (join $ds, $d1, $f1);
        } 
    }
    if ($#b < 0) {
      $s->echo_msg("WARN: ($prg) did not find any sql file.", 2); 
      return; 
    } else {
      $s->echo_msg("INFO: $#b SQL files will be executed.", 2); 
    }
    #
    # loop through each PL/SQL file
    my ($cmd, $cmd2) = ();
    my $r = []; 
    foreach my $f (@b) {
        if (! -f $f) {
            $s->echo_msg("ERR: ($prg) could not find sql file - $f.",0);
            next;
        }
        push @$r, $f; 
        my $f2 = "$f.tmp";
        $s->copy_file($f, $f2, "exit");    
        # $s->disp_file($f2);
        if ($^O !~ /^MSWin/i) { 
          $cmd = "ORACLE_HOME=$ohm;\nexport ORACLE_HOME;\n";
        } else {
          # $cmd = "set ORACLE_HOME=$ohm;\n";
          $s->echo_msg("INFO: ($prg) set ORACLE_HOME=$ohm and PATH=$ohm/bin",3); 
          $ENV{ORACLE_HOME}=$ohm;
          $ENV{PATH}="$ohm/bin"; 
          $cmd = ''; 
        }
        $cmd .= "$cfn -S $cs \@$f2";

        $cmd2 = $cmd;  $cmd2 =~ s/\</&lt;/g;
        $s->echo_msg("CMD: <pre>\n$cmd2\n</pre>",1);
#        if ($^O !~ /^MSWin/i) { 
#          ($r1, @a) = rexec($svr, $cmd, $usr, $pwd);
#        } else {
          open SQL, "$cmd|" or croak "ERR: ($prg) could not run $cmd: $!<br>\n";
          @a = <SQL>;   close SQL;
#        }        
        print "<pre>\n"; 
        my $ofn = $f; $ofn =~ s/\.(\w+)$/\.txt/; 
        push @$r, $ofn; 
        open OFN, ">$ofn" or 
          croak "ERR: ($prg) could not write to $ofn: $!<br>\n";
        foreach my $i (@a) { 
          next if $i =~ /^\s*$/; 
          # $s->echo_msg($i,0); 
          print OFN $i; 
        }
        close OFN; 
        print "</pre>\n";
        unlink $f2; 
    }
    wantarray ? @$r : $r;    
}


sub expand_vars {
    my ($s, $v, $hr) = @_;
    return if !$v || $v =~ /^\s*$/; 

    # Case 1: $plsql->echo
    my @n = ( $v =~ /(\$\w+\-\>\w+)/g ); 
    $s->echo_msg("INFO: expand_vars N1: @n<br>", 3) if @n; 
    foreach my $x  (@n) {
      my ($a, $b) = ( $x =~ /\$(\w+)\-\>(\w+)/g );
      $s->echo_msg("INFO: (a,b) = ($a,$b)<br>", 3); 
      if (! exists $hr->{$b} && $a =~ /^plsql/i) {
        $s->read_plsql("$b.sql",$hr); 		# read the plsql code      
      } 
      $v =~ s#\$$a\-\>$b\s*\;#$hr->{$b}#  if exists $hr->{$b}; 
      carp "    No code for \$$a\-\>{$b}."  if ! exists $hr->{$b};
    }; 
    
    # Case 2: $ar->{ifn}
    @n = ( $v =~ /(\$\w+\-\>\{\w+\})/g ); 
    $s->echo_msg("INFO: expand_vars N2: @n<br>",3) if @n;     
    foreach my $x  (@n) {
      my ($a, $b) = ( $x =~ /\$(\w+)\-\>\{(\w+)\}/g );
      $s->echo_msg("INFO: (a,b) = ($a,$b)<br>",3);       
      $v =~ s#\$$a\-\>\{$b\}#$$a->{$b}#  if exists $$a->{$b}; 
    }; 

    # Case 3: $hr{param}
    @n = ( $v =~ /(\$\w+\{\w+\})/g ); 
    $s->echo_msg("INFO: expand_vars N3: @n<br>",3) if @n;     
    foreach my $x (@n) {
      my ($a, $b) = ( $x =~ /\$(\w+)\{(\w+)\}/g );
      $s->echo_msg("INFO: (a,b) = ($a,$b)<br>",3);       
      $v =~ s#\$$a\{$b\}#$$a->{$b}#  if exists $$a->{$b}; 
    }; 

    # Case 4: $v1, $v2 
    my @m = ( $v =~ /[^\\](\$\w+)\s*/g );    # matched variables
    $s->echo_msg("INFO: expand_vars M: @m<br>",3) if @m; 
    return $v if (!@m); 
    foreach my $x (@m) { 
        my $y = $x; $y =~ s/^\$//; 
        $v =~ s{\$$y}{$hr->{$y}}    if  exists $hr->{$y}; 
    }
    return $v;
}

sub expand_code {
    my ($s, $fn, $hr) = @_;
    return if !$fn || $fn =~ /^\s*$/;
    croak "ERR: could not find file - $fn: $!\n" if ! -f $fn; 
    
    open FF, "<$fn" or croak "ERR: could not read file - $fn: $!\n"; 
    my @a = <FF>;
    close FF;
    open FF, ">$fn" or croak "ERR: could not write to file - $fn: $!\n";
    foreach my $v (@a) { 
      # Case 1: $plsql->echo
      if ($v =~ m/(\$\w+\-\>\w+)/g ) {
        my $x = $1; 
        $s->echo_msg("INFO: expand_code : $x<br>", 3); 
        my ($a, $b) = ( $x =~ /\$(\w+)\-\>(\w+)/g );
        $s->echo_msg("INFO: (a,b) = ($a,$b)<br>", 3); 
        $s->read_plsql("$b.sql",$hr) if (! exists $hr->{$b} && $a =~ /^plsql/i);
        if (exists $hr->{$b}) { 
          print FF "\n$hr->{$b}\n"; 
        } else { 
          $s->echo_msg("INFO: No code for \$$a\-\>{$b}.",1);
          print FF "  -- $v # sorry, no code"; 
        }
      } else { 
        print FF $v;
      }
    } 
    close FF;
}

=head2  read_plsql($fn, $pr)

Input variables:

  $fn - full path to a file name
  $pr - parameter array
        plsql_dir - directory where plsql files reside

Variables used or routines called:

  CGI::AppBuilder::Message
    echo_msg - echo messages

How to use:

  my $pr = $self->read_plsql('code_lib.ini');

Return: Hash array or ref of hash array - $pr

This method reads PL/SQL code files containing functions and procedures
in the format of key=values. Multiple lines is allowed for values as long
as the lines after the "key=" line are indented as least with two 
blanks. For instance:

  echo = procedure each ( msg clob, lvl NUMBER DEFAULT 999 ) IS
    BEGIN
      IF lvl <= p_lvl THEN dbms_output.put_line(msg); END IF;
    END;

  # you can define perl hash araay as well
  msg = {
    101 => "msg 101",
    102 => "msg 102"
    }
  # you can use variable as well
  js_var = /my/js/var_file.js
  js_src = /my/first/js/prg.js,$js_var
  # a comma (,) after sharp (#) make it not a comment
  my_sql = select sid, serial#,username from v\$session; 
  # you can use the ##include: to include more code files
  ##include: /my/codes/function_lib.sql

This will create a hash array of 

  $pr->{echo}  = proc ... end; 
  $pr->{desc}  = "This is a long description about the value"
  $pr->{msg}   = {101=>"msg 101",102=>"msg 102"}
  $pr->{js_var}= "/my/js/var_file.js";
  $pr->{js_src}= "/my/first/js/prg.js,/my/js/var_file.js";

=cut

sub read_plsql {
    my $s = shift;
    my ($fn, $pr) = @_;
    if (!$fn)    { carp "    No file name is specified."; return; }
    if (! $pr || ! exists $pr->{plsql_dir}) {
      carp "    No plsql directory is specified."; return;
    }
    # if file name does not have full path, we use plsql_dir
    $fn = join '/', $pr->{plsql_dir}, $fn if index($fn,'/') < 0; 
    if (!-f $fn) { carp "    File - $fn does not exist!"; return; }
    $s->echo_msg("  reading plsql code file - $fn...",2); 
    
    my ($k, $v, %h);
    open FILE, "< $fn" or
        croak "ERR: could not read to file - $fn: $!\n";
    while (<FILE>) {
      # 07/21/2010 (htu): enable included files
      if ($_ =~ /^\s*##include:\s*([\w\.\/]+)/i) {
        # we find a included file
        my $f2 = $1; 
        if (! -f $f2) {
          $s->echo_msg("WARN: could not find included file - $f2",1);
          next; 
        } else {
          $s->echo_msg("INFO: reading sub init file - $f2...",1);
        }
        # print "INFO (read_plsql): reading sub init file - $f2...<br>"; 
        ($k,$v) = ();
        open F2, "< $f2" or
          croak "ERR: could not read file - $f2: $!\n";
        while (<F2>) {          
          next if $_ =~ /^\s*#/ || $_ =~ /^\s*$/; 
          chomp;     			# remove line break
          my ($x, $y) = $s->_parseline2($_); 
          $k = $x if $x; $v = $y ;
          if ($x) { $h{$k} = $v; } else { $h{$k} .= " $v"; }
        }
        close F2;
        next;
      }
      # skip comment and empty lines
      next if $_ =~ /^\s*#/ || $_ =~ /^\s*$/; 
      chomp;               # remove line break
      my ($x, $y) = $s->_parseline2($_); 
      $k = $x if $x; $v = $y ;
      if ($x) { $h{$k} = $v; } else { $h{$k} .= " $v"; }
    }
    close FILE;
    foreach my $k (keys %h) { 
      $h{$k} =~ s/;\s*/;\n/g;				# add line break back
      $h{$k} =~ s/(declare|begin|then|else)/$1\n  /ig;	# add line break
      $h{$k} =~ s/(\>\>)/$1\n  /ig; 			# add line break
      $h{$k} =~ s/(\)\s*IS)/\n$1\n  /ig; 		# add line break
      $h{$k} =~ s/[^']?(from|where|order by|group by)/\n  $1/ig;	# add line break
      $h{$k} =~ s/(\s*,\s*\w+\s*=>)/\n  $1/ig;		# add line break
      $h{$k} =~ s/(,\s*\w+\s*(varchar|number|integer|date))/\n  $1/ig;	# add line break
    }
    if (ref($pr) =~ /^HASH/) {
      foreach my $k (keys %h) { $pr->{$k} = $h{$k}; }
    } else {     $pr = \%h;    } 
    return wantarray ? %$pr : $pr;
}

sub _parseline2 {
  my ($s, $rec) = @_;
  my ($k, $v) = (); 
  if ($rec =~ /^(\w+)\s*=\s*(.+)/) {
    $k = $1; $v = $2;  
  } elsif ($rec =~ /\s*(\w+)\s*=>\s*(.+)/) {  	# k1 => v1
    $k = ''; $v = $rec; 
  } else {
    $k = ''; $v = $rec; 
  }
  $v =~ s/^\s+//; $v =~ s/\s+$//;	# remove leading and trailing spaces 
  $v =~ s/\s*[^'"\(]#[^'",\)].*$//;	# remove inline comments
  $v =~ s/\s*[^'"\(]?--.*$//; 		# remove plsql inline comments
  return ($k,$v); 
}


1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version ported from ora_jobs.pl on 07/17/2010.

=item * Version 0.20

  08/12/2010 (htu): 
    1. added read_plsql, _parseline2
    2. modified expand_vars to use read_plsql
    3. modified exec_plsql to preload codes if the preload_code = 1

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

