package t::util;
# use t::lib;
use Carp;
use FindBin;
use File::Basename qw(fileparse);
use File::Spec;
use Cwd qw(cwd);
use Scalar::Util qw(blessed);
use Test::More;
use Test::Deep qw(cmp_details deep_diag methods set);
use Exporter();
use strict;

our @ISA=qw(Exporter);
our @EXPORT=qw(script scriptpath scriptfullpath scriptbasename scriptcode scripthead 
	       subtestdir rootpath
	       as_bool as_list flatten
	       is_quietly is_loudly isa_ok_quietly 
	       cmp_quietly cmp_set_quietly cmp_bag_quietly cmp_attrs 
	       report report_pass report_fail 
	       called_from callers diag_callers group val2idx
	     );
our($SCRIPT,$SCRIPTPATH,$SCRIPTBASENAME,$SCRIPTCODE,$SCRIPTHEAD,$ROOTPATH);
sub script {$SCRIPT or (($SCRIPT,$SCRIPTPATH)=fileparse($0) and $SCRIPT);}
sub scriptpath {$SCRIPTPATH or (($SCRIPT,$SCRIPTPATH)=fileparse($0) and $SCRIPTPATH);}
sub scriptfullpath {$FindBin::Bin}
sub scriptbasename {$SCRIPTBASENAME or 
		      (($SCRIPTBASENAME)=fileparse($0,qw(.t)) and $SCRIPTBASENAME);}
sub scriptcode {$SCRIPTCODE or ((($SCRIPTCODE)=script=~/\.(\w+)\.t$/)[0] and $SCRIPTCODE);}
sub scripthead {$SCRIPTHEAD or (($SCRIPTHEAD)=script=~/^(.*?)\.\d+/ and $SCRIPTHEAD);}
sub subtestdir {File::Spec->catdir(scriptpath,scriptbasename)}
sub rootpath {$ROOTPATH or $ROOTPATH=cwd}

sub as_bool {$_[0]? 1: 0}
sub as_list {my $list=@_>1? [@_]: (ref $_[0]? $_[0]: ([split(/\s+/,$_[0])]))}
sub flatten {map {'ARRAY' eq ref $_? @$_: $_} @_}

# like is but reports errors the way we want
sub is_loudly {
  my($actual,$correct,$label,$file,$line)=@_;
  my $ok=$actual eq $correct;
  pass($label), return 1 if $ok;
  report_fail($ok,"$label: expected $correct, got $actual",$file,$line);
}
# like is but reports errors the way we want
sub is_quietly {
  my($actual,$correct,$label,$file,$line)=@_;
  report_fail($actual eq $correct,"$label: expected $correct, got $actual",$file,$line);
}
# like isa_ok but reports errors the way we want
sub isa_ok_quietly {
  my($actual,$correct_class,$label,$file,$line)=@_;
  $label="$label - isa $correct_class";
  my $actual_class=blessed($actual);
  report_fail(defined $actual_class,$label,$file,$line,'not blessed') or return 0;
  report_fail($actual->isa($correct_class),$label,$file,$line,
	      "isn't a '$correct_class' is a '$actual_class'") or return 0;
  1;
}

# like cmp_deeply but reports errors the way we want
sub cmp_quietly {
  my($actual,$correct,$label,$file,$line)=@_;
  return 1 if !defined($actual) && !(defined $correct);
  report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
  my($ok,$details)=cmp_details($actual,$correct);
  report_fail($ok,"$label",$file,$line,$details);
}
# like cmp_set but reports errors the way we want
sub cmp_set_quietly {
  my($actual,$correct,$label,$file,$line)=@_;
  cmp_quietly($actual,Test::Deep::set(@$correct),$label,$file,$line);
}
# like cmp_bag but reports errors the way we want
sub cmp_bag_quietly {
  my($actual,$correct,$label,$file,$line)=@_;
  cmp_quietly($actual,Test::Deep::bag(@$correct),$label,$file,$line);
}
# $actual is object. $correct is HASH of attr=>value pairs wih Test::Deep decorations
sub cmp_attrs {
  my($actual,$correct,$label,$file,$line)=@_;
  report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
  my($ok,$details)=cmp_details($actual,methods(%$correct));
  report_fail($ok,"$label: attributes",$file,$line,$details) or return 0;
}

sub report {
  my($ok,$label,$file,$line,$details)=@_;
  pass($label), return 1 if $ok;
  ($file,$line)=called_from($file,$line);
  fail($label);
  diag("from $file line $line") if defined $file;
  if (defined $details) {
    diag(deep_diag($details)) if ref $details;
    diag($details) unless ref $details;
  }
  return 0;
}
sub report_pass {
  my($ok,$label)=@_;
  pass($label) if $ok;
  $ok;
}
sub report_fail {
  my($ok,$label,$file,$line,$details)=@_;
  return 1 if $ok;
  ($file,$line)=called_from($file,$line);
  fail($label);
  diag("from $file line $line") if defined $file;
  if (defined $details) {
    diag(deep_diag($details)) if ref $details;
    diag($details) unless ref $details;
  }
  return 0;
}
# emit stack trace - $callers set by callers function below
sub diag_callers {
  my($callers)=@_;
  return unless @$callers;
  for my $caller (@$callers) {
    my($package,$file,$line)=@$caller;
    diag("from $file line $line");
  }
}

# set ($file,$line) to last (lowest) caller in main if not already set
sub called_from {
  return @_ if $_[0];
  my($package,$file,$line);
  my $i=0;
  while (($package,$file,$line)=caller($i++)) {
    last if 'main' eq $package;
  }
  ($file,$line);
}
# set $callers if not already set 
# $what controls what is reported: 
#  default - 'mqin' - all callers in main
#  'all' - entire stack trace
#  'main' all callers in main
#  'top' - 1st caller in main
#  'last' - last caller in main - same as default
# in scalar context, returns ARRAY of ARRAYs [$package,$file,$line]
# in array context: default, 'top', 'last' return ($file,$line)
#                   others return array of ARRAYs [$package,$file,$line]
sub callers {
  # figure out arguments: 
  my($callers,$what,$package,$file,$line);
  if (@_ && 'ARRAY' eq ref $_[0]) {
    # arg is $callers
    ($callers,$what)=@_;
    $callers=undef unless @$callers; # empty $callers same as not set
  } elsif (@_==2 && !ref $_[0]) {
    # args are $file,$line
    ($file,$line)=@_;
    $callers=[[undef,$file,$line]] if defined $file;
  } elsif (@_>2 && !ref $_[0]) {
    # args are $file,$line,$what
    ($file,$line,$what)=@_;
    $callers=[[undef,$file,$line]] if defined $file;
  }
  $what='main' unless defined $what;
  unless (defined $callers) {
    $callers=[];
    my $i=0;
    while (($package,$file,$line)=caller($i++)) {
      $callers=[[$package,$file,$line]], last if $what eq 'last' && $package eq 'main';
      push(@$callers,[$package,$file,$line]) 
	if $what eq 'all' || ($what eq 'main' && $package eq 'main');
    }
    $callers=[[$package,$file,$line]] if $what eq 'top';
  }
  if (wantarray && ($what eq 'top' || $what eq 'last')) {
    ($package,$file,$line)=@{$callers->[0]};
    return ($file,$line);
  }
  wantarray? @$callers: $callers;
}

################################################################################
# code below here is mostly from other modules
# trash if we don't end up using it...
################################################################################

# # TODO: rewrite w/ Hash::AutoHash::MultiValued
# group a list by categories returned by sub.
# has to be declared before use, because of prototype
sub group (&@) {
  my($sub,@list)=@_;
  my %groups;
  for (@list) {
    my $group=&$sub($_);
    my $members=$groups{$group} || ($groups{$group}=[]);
    push(@$members,$_);
  }
  wantarray? %groups: \%groups;
}
# produce hash mapping each element of list to its position. doesn't worry about duplicates
sub val2idx {
  my $i=0;
  my %val2idx=map {$_=>$i++} @_;
  wantarray? %val2idx: \%val2idx;
}

# # like group, but processes elements that are put on list. 
# # sub should return 2 element list: 1st defines group, 2nd maps the value
# # has to be declared before use, because of prototype
# sub groupmap (&@) {
#   my($sub,@list)=@_;
#   my %groups;
#   for (@list) {
#     my($group,$value)=&$sub($_);
#     my $members=$groups{$group} || ($groups{$group}=[]);
#     push(@$members,$value);
#   }
#   wantarray? %groups: \%groups;
# }

# # specialized group: sub should return true or false
# # true elements added to group 'ok'; false elements added to 'fail'
# # has to be declared before use, because of prototype
# sub groupcmp (&@) {
#   my($sub,@list)=@_;
#   my %cmp;			# keys will be 'pass', 'fail'
#   for (@list) {
#     my $group=&$sub($_)? 'pass': 'fail';
#     my $members=$groups{$group} || ($groups{$group}=[]);
#     push(@$members,$_);
#   }
#   wantarray? %groups: \%groups;
# }

# # $actual,$correct are HASHES. 
# # like cmp_deeply but reports errors the way we want
# sub cmp_hashes {
#   my($actual,$correct,$label,$file,$line)=@_;
#   return 1 if !defined($actual) && !(defined $correct);
#   report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
#   my($ok,$details)=cmp_details($actual,$correct);
#   report_fail($ok,"$label",$file,$line,$details);
# }
# # $actual,$correct are ARRAYs. 
# # like cmp_deeply but reports errors the way we want
# sub cmp_lists {
#   my($actual,$correct,$label,$file,$line)=@_;
#   return 1 if !defined($actual) && !(defined $correct);
#   report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
#   my($ok,$details)=cmp_details($actual,$correct);
#   report_fail($ok,"$label",$file,$line,$details);
# }
# # $actual is ARRAY of objects
# # $correct is ARRAY of HASHES, interpreted as methods and results
# sub cmp_objlists {
#   my($actual,$correct,$correct_class,$label,$file,$line)=@_;
#   return 1 if !defined($actual) && !(defined $correct);
#   report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
#   my $actual_num=@$actual;
#   my $correct_num=@$correct;
#   report_fail(@$actual==$correct_num,
# 	      "$label: number of elements (is $actual_num should be $correct_num)",
# 	      $file,$line) or return 0;
#   for my $i (0..$correct_num-1) {
#     my $object=$actual->[$i];
#     report_fail(UNIVERSAL::isa($object,$correct_class),
# 		"$label: object $i class (is ".ref $object." should be $correct_class)",
# 		$file,$line) or return 0;
#     my $hash=$correct->[$i];
#     my($ok,$details)=cmp_details($object,methods(%$hash));
#     report_fail($ok,"$label: object $i contents",$file,$line,$details) or return 0;
#   }

# }


# TODO: if I keep them, these need to be moved earlier because of prototypes
# my $max_reports=5;
# sub report_cmp (\%;) {
#   my($cmp,$label,$reporter,$file,$line)=@_;
#   my $ok=!@{$cmp->{fail}||[]};
#   pass($label), return 1 if $ok;
#   _report_fail_cmp($cmp,$label,$reporter,$file,$line);
# }


# sub report_pass_cmp (\%;) {
#   my($cmp,$label)=@_;
#   my $ok=!@{$cmp->{fail}||[]};
#   pass($label) if $ok;
#   $ok;
# }
# sub report_fail_cmp (\%;) {
#   my($cmp,$label,$reporter,$file,$line)=@_;
#   my $ok=!@{$cmp->{fail}||[]};
#   return 1 if $ok;
#   _report_fail_cmp($cmp,$label,$reporter,$file,$line);
# }

# # when called, already know that test failed
# sub _report_fail_cmp {
#   my($cmp,$label,$reporter,$file,$line)=@_;
#   fail($label);
#   diag("from $file line $line") if defined $file;
#   my @pass=@{$cmp->{pass}||[]};
#   my @fail=@{$cmp->{fail}};
#   my @pass_reports=
#     map {UNIVERSAL::can($_,$reporter)? $_->$reporter: "$_"} @pass[0..min($max_reports-1,$#pass)];
#   my @fail_reports=
#     map {UNIVERSAL::can($_,$reporter)? $_->$reporter: "$_"} @fail[0..min($max_reports-1,$#fail)];
#   diag(scalar @pass.' elements passed. here are some: ',join('; ',@pass_reports));
#   diag(scalar @fail.' elements failed. here are some: ',join('; ',@fail_reports));
#   return 0;
# }

1;
