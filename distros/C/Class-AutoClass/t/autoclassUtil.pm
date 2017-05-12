package autoclassUtil;
use lib qw(t);
use strict;
use Carp;
use Test::More;
# NG 09-11-19: Test::Deep doesn't export cmp_details, deep_diag until recent version (0.104)
#              so we import them "by hand" instead. import of bag, methods was never needed.
# use Test::Deep qw(bag methods cmp_details deep_diag);
use Test::Deep;
*cmp_details=\&Test::Deep::cmp_details;
*deep_diag=\&Test::Deep::deep_diag;
# use Scalar::Util qw(reftype); # don't do it! Test::Deep exports reftype, too
use Scalar::Util;
use Exporter();
use Class::AutoClass;

our @ISA=qw(Exporter);
our @EXPORT=qw(as_hash cmp_attrs cmp_can cmp_hashes cmp_keys cmp_layers cmp_lists 
	       report report_fail report_pass);

sub as_hash {
  my $obj=shift;
  my %hash=%$obj;
  \%hash;
}

# $actual is object. $correct is HASH of attr=>value pairs wih Test::Deep decorations
sub cmp_attrs {
  my($actual,$correct,$label,$file,$line)=@_;
  report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
  my($ok,$details)=cmp_details($actual,methods(%$correct));
  report_fail($ok,"$label: attributes",$file,$line,$details) or return 0;
}

# $actual is object. $correct can be HASH or ARRAY of methods
#   if HASH, keys are attributes (really can be any methods)
sub cmp_can {
  my($actual,$correct,$label,$file,$line)=@_;
  report_fail(defined $actual,"$label: object defined",$file,$line) or return 0;
  my @correct_attrs='HASH' eq Scalar::Util::reftype $correct? keys %$correct: @$correct;
  my(@ok,@bad);
  map {UNIVERSAL::can($actual,$_)? push(@ok,$_): push(@bad,$_);} @correct_attrs;
  report_fail(!@bad,"$label: attributes defined",$file,$line,"attributes '@bad' not defined");
}

# $actual,$correct can be HASHs or ARRAYs. 
# if HASHs, keys are extracted and compared
sub cmp_keys {
  my($actual,$correct,$label,$file,$line)=@_;
  report_fail(defined $actual,"$label: keys defined",$file,$line) or return 0;
  my $actual_keys='HASH' eq Scalar::Util::reftype $actual? [keys %$actual]: $actual;
  my @correct_keys='HASH' eq Scalar::Util::reftype $correct? keys %$correct: @$correct;
  my($ok,$details)=cmp_details($actual_keys,bag(@correct_keys));
  report_fail($ok,"$label: keys",$file,$line,$details);
}

# $actual,$correct are ARRAYs. 
# this is a real crock.
#   nodes have names like xxx10,xxx11,xxx2. first digit defines 'layer'. 
#   all nodes of layer i must appear before any nodes of layer i+1. 
#   nodes of the same layer may appear in any order
# $correct only used to make sure $actual has the right nodes. its order doesn't matter
sub cmp_layers {
  my($actual,$correct,$label,$file,$line)=@_;
  my($ok,$details)=cmp_details($actual,bag(@$correct));
  report_fail($ok,"$label: nodes",$file,$line,$details) or return 0;
  my @layers=map {/^\D+(\d)/} @$actual;
  my @correct=sort {$a<=>$b} @layers; # the correct order is 1,2,3,...
  my($ok,$details)=cmp_details(\@layers,\@correct);
  report_fail($ok,"$label: order",$file,$line,$details);
}

# $actual,$correct are HASHES. 
# like cmp_deeply but reports errors the way we want
sub cmp_hashes {
  my($actual,$correct,$label,$file,$line)=@_;
  return 1 if !defined($actual) && !(defined $correct);
  report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
  my($ok,$details)=cmp_details($actual,$correct);
  report_fail($ok,"$label",$file,$line,$details);
}
# $actual,$correct are ARRAYs. 
# like cmp_deeply but reports errors the way we want
sub cmp_lists {
  my($actual,$correct,$label,$file,$line)=@_;
  return 1 if !defined($actual) && !(defined $correct);
  report_fail(defined $actual,"$label: defined",$file,$line) or return 0;
  my($ok,$details)=cmp_details($actual,$correct);
  report_fail($ok,"$label",$file,$line,$details);
}

sub report {
  my($ok,$label,$file,$line,$details)=@_;
  pass($label), return if $ok;
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
  fail($label);
  diag("from $file line $line") if defined $file;
  if (defined $details) {
    diag(deep_diag($details)) if ref $details;
    diag($details) unless ref $details;
  }
  return 0;
}
  


1;
