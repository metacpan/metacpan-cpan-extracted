#!perl -w
#
# CGI::Bus::Base - Base CGI::Bus SubObject Class
#
# admiral 
#
# 

package CGI::Bus::Base;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus;
use vars qw($VERSION @ISA $AUTOLOAD);
@ISA = qw();

1;


#######################


sub new {
 my $c=shift;
 my $s ={};
 bless $s,$c;
 $s =$s->initialize(@_);
 $s->parent->set('-reset')->{'-' .$s->classt}=1 if $s->parent;
 $s
}


sub initialize {
 my $s =shift;
 $s->parent(''); # cycle ref!
 $s->set(@_);
 $s
}


sub class {
 substr($_[0], 0, index($_[0],'='))
}


sub classt {
 substr($_[0]->class, rindex($_[0],'::')+2)
}


sub parent {
 scalar(@_) >1 ? ($_[0]->{'CGI::Bus'} =$_[1] ||$CGI::Bus::SELF) 
               :  $_[0]->{'CGI::Bus'}
}


sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($s, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $s->{$k} =$opt{$k};
 }
 $s
}


sub AUTOLOAD {
 my $s =shift;
 my $m =substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
 $s->parent->$m(@_)
}


sub cgi {
 shift->parent->{-cgi}
}


sub htmlescape {
 !defined($_[1]) ? '' : shift->parent->{-cgi}->escapeHTML(@_)
}


sub urlescape {
 !defined($_[1]) ? '' : shift->parent->{-cgi}->escape(@_)
}


sub param {
 shift->parent->{-cgi}->param(@_)
}


sub print {
 shift->parent->print(@_)
}


sub qparam {
 shift->parent->qparam(@_)
}


sub DESTROY {
 my $s =shift;
 delete $s->{'CGI::Bus'};
 $s
}


sub lng {
 $_[0]->{-lngbase} =$_[0]->parent->lngload($_[0]->class) if !$_[0]->{-lngbase};
 my $r =$_[0]->{-lngbase};
 $r = !defined($_[2]) ? $r->{$_[1]}
      :!defined($r->{$_[2]}) ||!defined($r->{$_[2]}->[$_[1]]) ? $_[2]
      :$r->{$_[2]}->[$_[1]];
 foreach my $e (@_[3..$#_]) {
   $r =~s/\$_/$e/e;
 }
 $r
}


