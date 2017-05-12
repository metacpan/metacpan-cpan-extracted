#!perl -w
#
# CGI::Bus::udata - User Data Store
#
# admiral 
#
# 

package CGI::Bus::udata;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use vars qw(@ISA);
@ISA =qw(CGI::Bus::Base);


my $fname ='_data.pl';

1;


#######################

sub keysplit {   # key filesystem dir
 my ($s,$k,$f) =@_;
 my $d =$s->{-ksplit} ||0;
    $d =length($k) if $d eq '0';
 my $r ='';
 if (ref($d) eq 'CODE') {
    local $_ =$k;
    foreach my $v (&$d($s, $k)) {
      $v =~s/([^a-zA-Z0-9])/uc sprintf("_%02x",ord($1))/eg;
      $r .='/' .$v;
    }
 }
 else {
    for (my $i =0; $i <length($k); $i +=$d) {
      my $v =substr($k, $i, $d);
      $v =~s/([^a-zA-Z0-9])/uc sprintf("_%02x",ord($1))/eg;
      $r .='/' .$v;
    }
 }
 $r .(defined($f) ? "/$f" : '')
}


sub keyname {    # dir name -> key value
 my ($s, $v) =@_;
 chop($v) if substr($v,length($v)-1,1) eq '$';
 $v =~s/[\\\/]//g;
 $v =~s/_(..)/chr(hex($1))/eg;
 $v
}


sub keypath {    # key filesystem path
 my ($s,$k,$f) =@_;
 $s->{-path} =$s->parent->dpath('udata') if !$s->{-path};
 $s->{-path} .$s->keysplit($k,$f)
}


sub keyfile {    # key file
 my ($s,$k,$f) =@_;
 $f =$fname if !defined($f);
 $s->fut->mkdir($s->keypath($k));
#$s->parent->launch('file')->open($s->keypath($k,$f),'rwc');
 $s->parent->launch('file', -name =>$s->keypath($k,$f), -mode =>'rwc');
}


sub unload {     # unload user data
 my $s =shift;
 eval{$s->{-file}->close if $s->{-file} && $s->{-file}->opened};
 $s->{-file}  =undef;
 $s->{-data}  =undef;
 $s->{-dataj} =undef;
 $s
}


sub load {       # load user data
 my $s =shift;
 my $u =$s->parent->user;
 eval{$s->{-file}->close if $s->{-file} && $s->{-file}->opened};
 if (-f $s->keypath($u,$fname)) {
    $s->{-file} =$s->keyfile($u);
    $s->{-data} =$s->{-file}->dumpload() ||$s->{-file}->dumpload() ||$s->{-file}->dumpload();
    if (!$s->{-data}) {
	$s->parent->die("Bad user '$u' data file format\n");
	$s->{-file} =undef;
	$s->{-data} ={};
    }	
 }
 else {
    $s->{-file} =undef;
    $s->{-data} ={}
 }
 $s->{-dataj} ={};  # join user groups params
 foreach my $g (sort @{$s->parent->ugroups}) {
   my $p =$s->keypath($g,$fname);
   next if !-f $p;
   my $d =$s->parent->fut->fdumpload($p) ||{};
   foreach my $k (keys %$d) {
      if    (!exists $s->{-dataj}->{$k}) {$s->{-dataj}->{$k} =$d->{$k}}
      elsif (ref($s->{-dataj}->{$k}) eq 'HASH')  {
          if(ref($d->{$k}) eq 'HASH')  {foreach my $e (keys %{$d->{$k}}) {$s->{-dataj}->{$k}->{$e} =$d->{$k}->{$e}}}
      }
      elsif (ref($s->{-dataj}->{$k}) eq 'ARRAY') {
          if(ref($d->{$k}) eq 'ARRAY') {push @{$s->{-dataj}->{$k}}, @{$d->{$k}}}
          elsif (exists $d->{$k} )     {push @{$s->{-dataj}->{$k}}, $d->{$k}}
      }
      elsif (defined($d->{$k}) || $d->{$k} ne '') { 
          $s->{-dataj}->{$k} =$d->{$k}
      }
   }
 }
 my $d =$s->{-data};
 foreach my $k (keys %{$s->{-dataj}}) {
      if    (!exists $s->{-dataj}->{$k}) {$s->{-dataj}->{$k} =$d->{$k}}
      elsif (ref($s->{-dataj}->{$k}) eq 'HASH')  {
          if(ref($d->{$k}) eq 'HASH')  {foreach my $e (keys %{$d->{$k}}) {$s->{-dataj}->{$k}->{$e} =$d->{$k}->{$e}}}
      }
      elsif (ref($s->{-dataj}->{$k}) eq 'ARRAY') {
          if(ref($d->{$k}) eq 'ARRAY') {unshift @{$s->{-dataj}->{$k}}, @{$d->{$k}}}
          elsif (exists $d->{$k} )     {unshift @{$s->{-dataj}->{$k}}, $d->{$k}}
      }
      elsif (defined($d->{$k}) && $d->{$k} ne '') {
          $s->{-dataj}->{$k} =$d->{$k}
      }
 }
 $s
}


sub store {      # store user data
 my $s =shift;
 my $u =$s->parent->user;
 $s->param(@_);
 return($s) if !$u;
 $s->{-file} =$s->keyfile($u) if !$s->{-file};
 $s->{-file}->dumpstore($s->{-data} ||{});
 $s
}


sub param {      # user data param
 my $s =shift;
 $s->load if !$s->{-data};
 if    (@_ ==0) {$s->{-data}}
 elsif (@_ ==1) {$s->{-data}->{$_[0]}}
 else  {
   for (my $i =0; $i <@_; $i +=2) {$s->{-data}->{$_[$i]} =$_[$i +1]}
   $s
 }
}


sub paramj {     # get user data joined param
 my $s =shift;
 $s->load if  !$s->{-dataj};
 @_ ==0 ? $s->{-dataj} 
 : exists $s->{-dataj}->{$_[0]} ? $s->{-dataj}->{$_[0]}
 : $s->{-data}->{$_[0]}
}


sub uglist {     # users and groups list
 my ($s, $d, $l) =@_;
 if (!defined($d)) {
    $l =[];
    $d ='';
    $s->{-path} =$s->parent->dpath('udata') if !defined($s->{-path});
 } 
 if (!$s->{-ksplit}) {
    $l =[eval{$s->parent->fut->globn($s->{-path} .'/*')}];
 }
 else {
    my $b =$s->{-path} .($d eq '' ? '' : "/$d");
    foreach my $f (eval{$s->parent->fut->globn("$b/*")}) {
       if (-f "$b/$f/$fname") {
          push @$l, (($d eq '' ? '' : "/$d") ."/$f")
       }
       elsif (-d "$b/$f") {
          $s->uglist(($d eq '' ? '' : "/$d") ."/$f", $l)
       }
    }
 }
 if (!defined($d) || $d eq '') {
    for (my $i =0; $i <scalar(@$l); $i++) { $l->[$i] =$s->keyname($l->[$i]) };
    $l =[sort @$l]
 }
 $l
}


