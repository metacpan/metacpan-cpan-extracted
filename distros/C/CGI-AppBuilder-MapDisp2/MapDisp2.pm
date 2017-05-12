package CGI::AppBuilder::MapDisp2;

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
our @EXPORT_OK   = qw(upload_sas_script 
                      get_scrnames
                      backup_file mk_dir
                   );
our %EXPORT_TAGS = (
    sas_scr => [qw(upload_sas_script)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::MapDisp2 - Display tasks

=head1 SYNOPSIS

  use CGI::AppBuilder::MapDisp2;

  my $sec = CGI::AppBuilder::MapDisp2->new();
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

=head2 upload_sas_script($q,$ar)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: None

=cut

sub upload_sas_script {
  my ($s, $q, $ar) = @_;

  my @c0 = caller(0);	my @c1 = caller(1);
  my $cls = (exists $c1[3]) ? $c1[3] : ''; 
  my $prg = "$cls [$c0[2]] -> $c0[3]"; 

  $s->disp_header($q,$ar,1);

  # get parameters
  my $vs = 'task,file_name,app_user,dir_sep,sel_sn1';
  my ($tsk,$sfn,$apu,$ds,$svr) = $s->get_params($vs, $ar);
     $ds  = ($ds) ? $ds : '/'; 
  if (! $svr) {
    $s->echo_msg("ERR: ($prg) sever name has not been defined.",0);
    return; 
  }
  if (! $sfn) {
    $s->echo_msg("ERR: ($prg) no upload file is specified.",0);
    return; 
  }
  my $adr = eval $s->set_param('all_dir', $ar);

  my $sdr = (exists $adr->{$svr}{sas}) ? $adr->{$svr}{sas} : '';
  if (! $sdr) {
    $s->echo_msg("ERR: ($prg) target folder has not been defined.",0);
    return; 
  }
  if (! $apu) {
    $s->echo_msg("ERR: ($prg) no application user name is specified/available.",0);
    return; 
  }
  my $udr = join $ds, $sdr, $apu;
  $ar->{upload_dir} = $udr; 

  $s->mk_dir($sdr); 
  $s->mk_dir($udr);   

  $s->upload_file($q, $ar); 
  
  $s->echo_msg("INFO: ($prg) File - $sfn is uploaded to $sdr.", 1);

  return;
} 


sub get_scrnames {
  my ($s, $ar) = @_;

  my @c0 = caller(0); my @c1 = caller(1);
  my $cls = (exists $c1[3]) ? $c1[3] : ''; 
  my $prg = "$cls [$c0[2]] -> $c0[3]"; 

  my $ds = (exists $ar->{dir_sep}) ? $ar->{dir_sep} : '';
     $ds = ($^O =~ /MSWin/i)? '\\': '/'	if ! $ds; 

  # get parent id, server id, study id and list id
  my $vs = 'pid,sid,study_id,list_id,app_user'; 
  my ($pid,$sn,$sid,$lid,$apu) = $s->get_params($vs,$ar); 
    $sn  = $ar->{sel_sn1} if !$sn && exists $ar->{sel_sn1}; 
    $sid = 0 if !$sid; 
    $lid = 0 if !$lid; 

  my $ad 	= eval $s->set_param('all_dir', $ar); 	# all dir array
  my $dir 	= $ad->{$sn}{sas};			# sas dir
     $dir	= join $ds, $dir, $apu;
     
  my $r = []; 				# result array
  if (!$sn) {
    $s->echo_msg("ERR: ($prg) server id is not provided.", 0);
    return wantarray ? @$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) server id is $sn.", 3);
  } 
  if (! -d $dir) {
    $s->echo_msg("WARN: ($prg) could not find dir - $dir.", 1);
    return wantarray ? @$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) spec dir is $dir.", 3);
  }
  opendir DD, "$dir" or die "ERR: could not opendir - $dir: $!\n";
  my @a = sort (grep { !/^\./ && !/\.bak$/ && -f "$dir/$_" } readdir DD);
  closedir DD;
  for my $i (0..$#a) { push @$r, [$a[$i],$a[$i],0]; }
  unshift @$r, ['', '__Select__',1]; 

  wantarray ? @$r : $r; 
}


sub mk_dir {
  my ($s, $dir) = @_; 
  # $dir - directory
  
  # $package,   $filename, $line,       $subroutine, $hasargs,
  # $wantarray, $evaltext, $is_require, $hints,      $bitmask
  my @c0 = caller(0); 		my @c1 = caller(1);
  my $cls = (exists $c1[3]) ? $c1[3] : ''; 
  my $prg = "$cls [$c0[2]] -> $c0[3]"; 

  if (! -d $dir) {
    eval { mkpath($dir,0,0777) };
    if ($@) { 
      my $m = "ERR: ($prg [" . __LINE__ . "]) ";
        $m .= "could not mkdir - $dir: $!: $@<br>\n";
      $s->echo_msg($m,0);
      return;
    } 
    if ($^O !~ /^MSWin/i) { 				# non window
        system("chmod -R ugo+w $dir"); 
    }
  }
}

sub backup_file {
  my ($s, $ffn, $ar) = @_; 
  # $ffn - file name
  # $ar  - parameter array 
  # $bdr - backup dir  

  my @c0 = caller(0); my @c1 = caller(1); 
  my $cls = (exists $c1[3]) ? $c1[3] : ''; 
  my $prg = "$cls [$c0[2]] -> $c0[3]"; 

  my $ds = ($^O =~ /MSWin/i)? '\\': '/'; 
  my ($bcp) = $s->get_params('bak_copies',$ar); 
     $bcp = ($bcp) ? $bcp : 10; 	# default it to 10 copies
  my ($fname, $path, $sfx) = fileparse($ffn,qr{\..*});
  
  my $bdr = "${path}baks"; 
  my $f1  = $ffn; 
  my $f2  = join $ds, $bdr, "$fname$sfx"; 
  
  $s->mk_dir($bdr) if (! -d $bdr);

  if (! -f $f2) {
    copy($f1,$f2) or 
      $s->echo_msg("ERR: ($prg [" .__LINE__ . 
      "]) Copy failed from $f1 to $f2: $!",0);
    return; 
  }

  opendir DD, "$bdr" or croak "ERR: ($prg) could not opendir - $bdr: $!\n";
  my @a = sort { (stat("$bdr/$a"))[9] <=>  (stat("$bdr/$b"))[9] } 
               (grep { /$fname/ && !/^\./ } readdir DD);
  closedir DD; 

  my $n = 0; 
  my ($m) = ($a[$#a] =~ /\.(\d+)$/); 
      $m  = 1 + $m; 
  $n = ($m) % $bcp; 
  $n = sprintf "%03d", $n; 
  $f2 = "$f2.$n";
  copy($f1,$f2) or 
      $s->echo_msg("ERR: ($prg [" .__LINE__ . 
      "]) Copy failed from $f1 to $f2: $!",0);
  return; 
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from MapDips on 07/22/2013.

=item * Version 0.20

  07/22/2013 (htu): start this PM
  
=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::AppBuilder, File::Xcopy,
CGI::AppBuilder::Message

=head1 AUTHOR

Copyright (c) 2013 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

