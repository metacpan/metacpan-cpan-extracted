package CGI::AppBuilder::Define;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI::Pretty ':standard';
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Path; 

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw(def_inputvars );
our @EXPORT_OK   = qw(def_inputvars 
                   );
our %EXPORT_TAGS = (
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::PLSQL - Oracle PL/SQL Procedures

=head1 SYNOPSIS

  use CGI::AppBuilder::Define;

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

=head2 def_inputvars($ar)

Input variables:

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

=cut  

sub def_inputvars {
    my ($s, $ar) = @_;
    
    my $r = {};
    my $prg = 'AppBuilder::Define->def_inputvars'; 
    # set pre-defined variables
    my ($pid,$sn,$s2,$ds,$tsk) = ();
    $pid = $ar->{pid}		if exists $ar->{pid};
    $sn  = $ar->{target}  	if exists $ar->{target};
    $sn  = $ar->{sel_sn1} 	if exists $ar->{sel_sn1} && !$sn;
    $tsk = $s->set_param('task', $ar);
    if (!$pid) {
        print header("text/html");
        print start_html(%{$ar->{html_header}});
        $s->echo_msg("ERR: ($prg) project id has not been defined.",0);
        $s->disp_param($ar);
        return;
    }    
    if (!$sn) {
      my $msg = "ERR: ($prg) target/server/database has not been selected.";
      $s->echo_msg($msg,0)  if $tsk !~ /^(login)/;
      return;
    }    
    $s2 = $s->set_param('args', $ar) 	if exists $ar->{args}; 
    $s2 = $s->set_param('sel_sn2', $ar) if exists $ar->{sel_sn2} && !$s2; 
    if ($s2) { 
        my @b = split /:/, $s2;
        for my $i (0..$#b) { $r->{"a$i"} = $b[$i]; }
    }
    $ds = $ar->{dir_sep} 			if exists $ar->{dir_sep}; 
    $ds = ($^O =~ /^MSWin/i) ? '\\' : '/' 	if ! $ds; 
    $ar->{ds} = $ds				if ! exists $ar->{ds}; 

    my $usr_gid = (exists $ar->{guid} && $ar->{guid}) ? $ar->{guid} : ""; 
    my ($usr_sid,$usr_uid,$usr_tmo) = split /:/, $usr_gid; 
    $r->{guid}  = $usr_gid 	if $usr_gid; 
    $r->{pid}	= $pid;	$ar->{pid} = $pid;     
    $r->{sid}   = $sn;	$ar->{sid} = $sn; 
    $r->{dtm}	= strftime "%Y%m%d_%H%M%S", localtime; 
    $r->{dt} 	= substr $r->{dtm}, 0, 8;
    $r->{tm} 	= substr $r->{dtm}, 9, 6;
    $r->{y4} 	= substr $r->{dtm}, 0, 4;
    $r->{mm} 	= substr $r->{dtm}, 4, 2;
    $r->{dd} 	= substr $r->{dtm}, 6, 2;
    $r->{hh} 	= substr $r->{dtm}, 9, 2;
    $r->{mi} 	= substr $r->{dtm},11, 2;
    $r->{ss} 	= substr $r->{dtm},13, 2;
    $r->{vbs}   = $ar->{Verbose} if exists $ar->{Verbose}; 
    $r->{ds}    = $ds;     			# directory separator
    $r->{web_url} = "http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}"; 
    $r->{web_url} =~ s/(\?.*)//; 			# remove parameters
    $r->{cgi_url}  = $ar->{script_url}	if exists $ar->{script_url}; 
    $ar->{ymd} = join $ds, $r->{y4}, $r->{mm}, $r->{dd}; 
    $ar->{hms} = "$r->{hh}$r->{mi}$r->{ss}"; 
    $ar->{web_url} = $r->{web_url}; 
    my ($usr_app,$usr_u2) = $s->get_params('app_user,user_uid',$ar);
    my $uuu = ($usr_uid) ? $usr_uid : $usr_u2; 
       $uuu = $usr_app		if !$uuu && $usr_app;
    if (!$uuu) {
        print header("text/html");
        print start_html(%{$ar->{html_header}});
        $s->echo_msg("ERR: ($prg) user id has not been defined.",0);
        $s->disp_param($ar);
        return;
    }        
    $r->{app_user}  = $uuu; 
    $ar->{app_user} = $uuu;
    
    # my $tsk	= lc $ar->{task};			# task name
    my $odr = {}; 				 	# Out dir
       $odr = eval $s->set_param('out_dir', $ar)
              if exists $ar->{out_dir} && $ar->{out_dir};
    # set outdir 
    my $ldir = ''; 
    if (exists $odr->{$sn}) {
      $r->{db_outdir}  = (exists $odr->{$sn}{db})  ? $odr->{$sn}{db}  : ''; 
      $r->{web_outdir} = (exists $odr->{$sn}{web}) ? $odr->{$sn}{web} : ''; 
      $r->{rpt_outdir} = (exists $odr->{$sn}{rpt}) ? $odr->{$sn}{rpt} : ''; 
      $r->{dsp_url}    = (exists $odr->{$sn}{dsp}) ? $odr->{$sn}{dsp} : '';
      $ldir            = (exists $odr->{$sn}{log}) ? $odr->{$sn}{log} : ''; 
      $r->{drv_map}    = (exists $odr->{$sn}{drv}) ? $odr->{$sn}{drv} : '';
    } else {
      $r->{db_outdir}  = $ar->{outdir} if exists $ar->{outdir}; 
      $r->{web_outdir} = $ar->{outdir} if exists $ar->{outdir}; 
      $r->{rpt_outdir} = $ar->{outdir} if exists $ar->{outdir};
      $r->{drv_map}    = '\\\\$sn';
      # $r->{dsp_url}    = $ar->{outdir} if exists $ar->{outdir}; 
      $ldir            = $ar->{outdir} if exists $ar->{outdir}; 
    }
    $r->{dsp_url} = $r->{web_url} if ! $r->{dsp_url}; 
    $r->{tgt_dir} = join $ds, $r->{web_outdir}, $sn, $tsk;
    $r->{log_dir} = join $ds, $r->{tgt_dir}, $r->{y4}, $r->{mm};
    $r->{sql_fn}  = join $ds, $r->{log_dir}, "s$r->{dtm}.sql"; 
    $ar->{drv_map} = $r->{drv_map}; 

    # set db connection
    my $dbc = eval $s->set_param('db_conn', $ar);   	# DB connections
    my $tcn = {};   					# Task connections
       $tcn = eval $ar->{task_conn} 
              if exists $ar->{task_conn} && $ar->{task_conn};
    $r->{cs} = ( exists $tcn->{$sn}{$tsk}) ? $tcn->{$sn}{$tsk} : 
             ((exists $dbc->{$sn}) ? $dbc->{$sn} : ""); 
    $ar->{cs} = $r->{cs}; 				# save the cs

    # set custom variables
    my $dvs = $s->set_param('defined_vars', $ar);
       $dvs =~ s/\s*,\s*/,/; 
    foreach my $v (split /,/, $dvs) {
      if (! exists $ar->{$v}) { 
        $s->echo("Warn: variable $v has not been defined.", 1);
      } else {
        if ($ar->{$v} =~ /^\s*[\{|\[]/) {	# if it starts with { or [
          $r->{$v}  = eval $ar->{$v}; 		#   it must be an array
        } else {				# if not
          $r->{$v}  = $ar->{$v}; 		#   it is just a value
        }
      }
    }
    # get sqlplus 
    my $scn = eval $s->set_param('svr_conn', $ar);  	# Server connections
    my ($svr,$usr,$pwd,$ohm) = ();
    my $vhm = 'ORACLE_HOME'; 
       $ohm = $ENV{$vhm} 	if exists $ENV{$vhm} && $ENV{$vhm}; 
       $ohm = $scn->{orahome}	if !$ohm && exists $scn->{orahome}; 
       $svr = $scn->{svr}	if exists $scn->{svr};
       $usr = $scn->{usr}	if exists $scn->{usr};
       $pwd = $scn->{pwd}	if exists $scn->{pwd};
       
    my $cfn  = join $ds, $ohm, 'bin', 'sqlplus';	# command file name
       $cfn .= ".exe" 	if ($^O =~ /^MSWin/i); 
    $ar->{sqlplus}	= $cfn;			# stored the sqlplus 
    $ar->{ohm}		= $ohm;			# Oracle Home
    $ar->{svr}		= $svr;			# OS/DB server
    $ar->{usr}		= $usr;			# OS user
    $ar->{pwd}		= $pwd;			# OS user password
    # define inputs
    for my $i (0..50) {
      my ($x,$y) = ("a$i", "in_a$i"); 
# print "($x,$y) = ($ar->{$x}, $ar->{$y})<br>\n";       
      if (!exists $ar->{$x} && exists $ar->{$y}) {
        $ar->{$x} = $ar->{$y} 
          if ($x =~ /id$/i && $ar->{$y} =~ /^\d+$/) || $ar->{$y}; 
      }
    }
    # get OS user
    my $os_user = ($r->{cs}) ? $s->get_osuser($ar) : ''; 
    $ar->{os_user} = $os_user;
    $r->{os_user}  = $os_user; 

    my $osu = $os_user;
       $osu =~ s/[\.\\]+/_/g	if $osu;
       $osu =~ s/\s*$//g	if $osu; 

    # get rpt_outdir
    if ($r->{rpt_outdir}) {
      my $ddir = join $ds, $r->{rpt_outdir}, $osu, $r->{y4}, $r->{mm}, $r->{dd}; 
      eval { mkpath($ddir,0,0777) };
      $s->echo_msg("ERR: ($prg) could not mkdir - $ddir: $!: $@",0) if ($@);
      $r->{rpt_outdir} 	= $ddir; 
      $ar->{rpt_outdir}	= $ddir;
    } else {
      $s->echo_msg("WARN: ($prg) - rpt_outdir is not defined.", 2); 
      $r->{rpt_outdir} 	= ''; 
      $ar->{rpt_outdir}	= '';
    }

    # get db_outdir
    if ($r->{db_outdir}) {
      my $ddir = join $ds, $r->{db_outdir}, $osu, $r->{y4}, $r->{mm}, $r->{dd}; 
       $r->{db_outdir} = $ddir;
      $ar->{db_outdir} = $ddir; 
      # eval { mkpath($ddir,0,0777) };
      # $s->echo_msg("ERR: ($prg) could not mkdir - $ddir: $!: $@",0) if ($@);
    } else {
      $s->echo_msg("WARN: ($prg) - db_outdir is not defined.", 2); 
    }

    # get log dir
    if ($ldir) {
      $ldir = join $ds, $ldir, $osu, $r->{y4}, $r->{mm}, $r->{dd}; 
      # $ldir = join $ds, $ldir, $r->{y4}, $r->{mm}, $r->{dd}; 
       $r->{log_outdir} = $ldir;
      $ar->{log_outdir} = $ldir; 
      eval { mkpath($ldir,0,0777) };
      $s->echo_msg("ERR: ($prg) could not mkdir - $ldir: $!: $@",0) if ($@);
    } else {
      $s->echo_msg("WARN: ($prg) - log_outdir is not defined.", 2); 
    }

    # set form parameters
    my $amg = eval $s->set_param('arg_msgs',$ar); 	# arg msgs
    my $far = $amg->{$tsk}; 				# form message
    for my $i (0..$#$far) {		# each variable
      my $k = $far->[$i][0];		# name/key: study_id
      my $m = $far->[$i][1];		# message
      my $d = $far->[$i][2];		# default    
      my $n = $far->[$i][3];		# desc/required
      my $v = (exists $ar->{$k}) ? $ar->{$k} : ''; 
      $r->{$k} = $v;
    }
    wantarray ? @$r : $r; 
}


=head2 read_text_file($fn, $dvr)

sub read_text_file {
    my $s = shift;
    my ($fn, $dvr) = @_;
    if (!$fn)    { carp "    No file name is specified."; return; }
    if (!-f $fn) { carp "    File - $fn does not exist!"; return; }
    
    my ($t);
    open FILE, "< $fn" or
        croak "ERR: could not read to file - $fn: $!\n";
    while (<FILE>) {
        # skip comment and empty lines
        next if $_ =~ /^\s*#/ || $_ =~ /^\s*$/; 
        s/\s*[^'"\(]#[^'",\)].*$//; 	# remove inline comments
        chomp;               		# remove line break
        $t .= $_;
    }
    close FILE;
    return $t;
}


=cut

1;
