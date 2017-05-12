package CGI::AppBuilder::MapForms;

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
our @EXPORT_OK   = qw(get_ids get_dblinks get_meddra_version get_iso_version 
                   get_studyid get_jobid get_hjobid get_xlsfiles
                   get_domains get_cdviewnames
                   );
our %EXPORT_TAGS = (
    usrforms => [qw(disp_usr_form)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::MapForms - Create or display Task froms

=head1 SYNOPSIS

  use CGI::AppBuilder::MapForms;

  my $sec = CGI::AppBuilder::MapForms->new();


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
    $vs .= ',list_id,sponsor,spec_id,id_type'; 
  foreach my $k (split /,/,$vs) { 
    $r->{$k} = $ar->{$k} if exists $ar->{$k} && $ar->{$k};
  }
  
  # get ids from input field
  if ($ar->{id_type} && exists $ar->{sel_sn2} && $ar->{sel_sn2}) { 
    if ($ar->{id_type} =~ /^specid/i) {
      $r->{spec_id} = $ar->{sel_sn2}	if !$r->{spec_id}; 
    } elsif ($ar->{id_type} =~ /^listid/i) {
      $r->{list_id} = $ar->{sel_sn2} 	if !$r->{list_id};  
    } elsif ($ar->{id_type} =~ /^clientid/i) {
      $r->{cln_id} = $ar->{sel_sn2} 	if !$r->{cln_id};  
    } elsif ($ar->{id_type} =~ /^prjid/i) {
      $r->{prj_id} = $ar->{sel_sn2} 	if !$r->{prj_id};  
    } else {
      $r->{study_id} = $ar->{sel_sn2}	if !$r->{study_id}; 
    }
  } 
  # assign the values back to $ar 
  foreach my $k (split /,/, $vs) { 
    $ar->{$k} = (exists $r->{$k} && $r->{$k}) ? $r->{$k} : ''; 
  }

  wantarray ? $r : %$r; 
}


=head2 get_xlsfiles ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_xlsfiles {
  my ($s, $ar) = @_;

  my $prg = 'MapForms->get_xlsfiles'; 

  my $ds = '/'; 
     $ds = '\\' if $^O =~ /MSWin/i; 
  # get parent id, server id, study id and list id
  my $vs = 'pid,sid,study_id,list_id'; 
  my ($pid,$sn,$sid,$lid) = $s->get_params($vs,$ar); 
    $sn  = $ar->{sel_sn1} if !$sn && exists $ar->{sel_sn1}; 
    $sid = 0 if !$sid; 
    $lid = 0 if !$lid; 

  my $ad 	= eval $s->set_param('all_dir', $ar); 	# all dir array
  my $dir 	= $ad->{$sn}{map};			# map dir
     $dir	= join $ds, $dir, (sprintf "${sn}_%03d", $sid);
     
  my $r = []; 				# result array
  if (!$sn) {
    $s->echo_msg("ERR: ($prg) server id is not provided.", 0);
    return wantarray ? @$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) server id is $sn.", 3);
  } 
  if (! -d $dir) {
    $s->echo_msg("ERR: ($prg) could not find dir - $dir.", 0);
    return wantarray ? @$r : $r;
  } else {
    $s->echo_msg("INFO: ($prg) spec dir is $dir.", 3);
  }
  opendir DD, "$dir" or die "ERR: could not opendir - $dir: $!\n";
  my @a = sort grep !/\.bak$/, (grep /\.xls$/i, readdir DD);
  closedir DD;
  for my $i (0..$#a) {
    my $k = $a[$i];
    my $v = $a[$i];
    if ($i == $#a) {
      push @$r, [$k,$v,0];
    } else {
      push @$r, [$k,$v,0];
    }
  }
  # $s->disp_param($r); 
  unshift @$r, ['', '__Select__',1]; 

  wantarray ? @$r : $r; 
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


=head2 get_domains ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_domains {
  my ($s, $ar) = @_;

  my $r = []; 				# result array
  my $whr  = "";
     $whr .= "where list_id = $ar->{list_id} "
             if exists $ar->{list_id} && $ar->{list_id};
     $whr .= ' group by sdtm_domain order by sdtm_domain'; 
  my $rr = $s->run_sqlcmd($ar,'sdtm_domain','sp_specs', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    push @$r, [$rr->[$i]{sdtm_domain},$rr->[$i]{sdtm_domain},0];
  }
  unshift @$r, ['ALL', 'ALL',0]; 
  unshift @$r, ['0', '__Select__',1]; 

  wantarray ? @$r : $r; 
}


=head2 get_cdviewnames ($ar)

Input variables:

  $ar	- array ref containing the following variables:
  
Variables used or routines called:

  None

How to use:

Return: array/hash array or its ref

=cut

sub get_cdviewnames {
  my ($s, $ar) = @_;

  my $r     = []; 				# result array
  my $id    = 'list_id'; 
  my $f_lid = (exists $ar->{$id} && ($ar->{$id}==0 || $ar->{$id})) ? $ar->{$id} : 0; 
  my $whr  = "";
     $whr .= "where list_id = $ar->{list_id} " if $f_lid; 
     $whr .= ' group by list_id, obj_name'; 
  my $rr = $s->run_sqlcmd($ar,'obj_name','sp_codes', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    push @$r, [$rr->[$i]{obj_name},$rr->[$i]{obj_name},0];
  }
  unshift @$r, ['%', 'ALL',0]; 
  unshift @$r, ['0', '__Select__',1]; 

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
  my $whr  = "where upper(job_status) = 'REQUESTED' ";
     $whr .= "and upper(job_type) like 'SDTM%' "; 
     $whr .= "and list_id = $ar->{list_id} " 
             if exists $ar->{list_id} && $ar->{list_id};
     $whr .= ' order by job_id'; 
  my $rr = $s->run_sqlcmd($ar,'job_id,job_args','sp_jobs', $whr);
  # $s->disp_param($rr);  
  
  for my $i (0..$#$rr) {
    my $v1 = $rr->[$i]{job_id};
    my $tp = $rr->[$i]{job_args};
    my ($v2) = ($tp =~ /dmn=([\w,]+)/); 
        $v2 = "$v1 - $v2"; 
    push @$r, [$v1,$v2,0];
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

