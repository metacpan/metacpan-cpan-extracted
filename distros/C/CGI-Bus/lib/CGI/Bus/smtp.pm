#!perl -w
#
# CGI::Bus::smtp - SMTP Sender
#
# admiral 
#
# 

package CGI::Bus::smtp;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use vars qw(@ISA);
@ISA =qw(CGI::Bus::Base);


1;


#######################


sub smtp {
 my $s =shift;
 $s->set(@_);
 $s->{-smtp} =eval {local $^W=undef; eval("use Net::SMTP"); Net::SMTP->new($s->{-host})};
 die("SMTP host '" .$s->{-host} ."' $@\n") if !$s->{-smtp} ||$@;
 $s->{-smtp}
}


sub mailsend { # from, to, msg rows
 my $s    =shift;
 my $host =$s->{-host};
 my $from =$_[0] !~/:/ ? shift : undef;
 my $to   =ref($_[0])  ? shift : undef;
 my $dom  =$s->{-domain};
 foreach my $r (@_) {last if $from && $to;
   if    (ref($r))  {$to =$r; $r ='To:'.join(',',@$r)}
   elsif (!$from && $r=~/^(from|sender):(.*)/i) {$from =$2}
   elsif (!$to   && $r=~/^to:(.*)/i)            {$to   =[split /,/,$1]}
 }
 $s->parent->pushmsg("SMTP msgsend $host $from -> ".join(',',@$to));
 local $^W=undef;
 my $smtp =$s->smtp(); $s->{-smtp} =undef;
 # $s->parent->pushmsg("SMTP mail: " .$s->addrtr($from));
 $smtp->mail($s->addrtr($from))
                            || $s->die("SMTP From: $from\n");
 # $s->parent->pushmsg("SMTP to: " .join(',',map {$s->addrtr($_)} @$to));
 $smtp->to(map {$s->addrtr($_)} @$to)
                            || $s->die("SMTP To: " .join(', ',@$to) ."\n");
 $smtp->data(join("\n",@_)) || $s->die("SMTP Data\n");
 $smtp->dataend()           || $s->die("SMTP DataEnd\n");
 $smtp->quit;
 1
}


sub addrtr {	# address translation
  ($_[1] =~/^([^\\]+)\\(.+)$/ 
	? $2 
	: $_[1])
 .((index($_[1],'@') <0) && $_[0]->{-domain}
	? '@' .$_[0]->{-domain} 
	: '')
}