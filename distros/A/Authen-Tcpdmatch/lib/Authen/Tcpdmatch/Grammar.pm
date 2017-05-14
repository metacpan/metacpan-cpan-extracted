# Copyright (c) 2003 Ioannis Tambouras <ioannis@earthlink.net> .
# All rights reserved.
 
package  Authen::Tcpdmatch::Grammar;

use strict;
use Attribute::Handlers;
use Parse::RecDescent;
use warnings;

our $VERSION='0.01';


$Parse::RecDescent::skip = '[, \t]*' ;



our $grammar = q(
        { use NetAddr::IP; no strict 'refs'}
        { our ( $found, $e, $side, $remote, $service, $OK_remote, $OK_service)             }
	{ sub found     { $OK_service && $OK_remote  or  undef                             }}
	{ sub init      { ($service, $remote)=@_; @_= $OK_remote = $OK_service = $found = undef}}
	{ sub register  { ${"OK_$side"} = !$e}                                             }
        { sub tally     { register    if  $_[0] eq ${"$side"}                              }}
	{ sub dot_host  { (my $ip = $_[0]) =~ s!\.!\\\.!g;  register if $remote =~ /$ip$/  }}
	{ sub ip_dot    { (my $ip = $_[0]) =~ s!\.!\\\.!g;  register if $remote =~ /^$ip/  }}
	{ sub ALL       { register                                                         }}
	{ sub LOCAL     { register    if $remote !~ /\./                                   }}
	{ sub maskit    { my $r = new NetAddr::IP $remote  or return;
                          register   if (NetAddr::IP->new(shift)||return)  ->contains($r)  }}

   

        Start :     { init $arg[0], $arg[1] ; 'true'}
                    Line(s)   /\Z/
                    {$return = $found}
        Start:      {$return = $found}

        Line:       { $OK_remote = $OK_service = undef }
        Line:       { $side   = 'service', $e=0  }      List['']       ':'
                    { $side   = 'remote' , $e=0  }      List['']       EOL(?)
                    { found  and  $found  = 1    }
		    <reject: $found>
        Line:       Comment
        Line:       <resync>


        List   :    <leftop: Member[$arg[0]](s)   'EXCEPT'   List[ $e^=1 ] >
        List   :    Member[ $arg[0] ](s)

        Member :    Wildcard[ $arg[0] ]
        Member :    Pattern[  $arg[0] ]
        Member :    Netmask[  $arg[0] ]
	Member :    ...!/EXCEPT/i   /[A-Za-z]\w*/    
		    { tally $item[2], $arg[0]  ; 'true' }


        Wildcard:   / \b  (ALL | LOCAL)  \b /x
                    { &{"$item[1]"}( $arg[0] ) ; 'true'}
        Pattern:    ...!/\w/    m!\.\S+!  
                    { dot_host   $item[-1] ; 'true'}


        Pattern:    m!\S+\.!     ...!/[\w]/
                    { ip_dot   $item[1] ; 'true'}

        Netmask:    {} <rulevar: $octet  = qr/\d{1,3}/ >
                       <rulevar: $o3     = qr/(?:\.$octet){1,3}/ >
        Netmask:    m! \b  $octet $o3   (?: /$octet(?:$o3)? )? \b  !xo
                    { maskit $item[1] , $arg[0]   ;  'true'}


	EOL    :    /[\n]/
	Comment:    /#.*\n/   
);



sub  TcpdParser : ATTR  { ${$_[2]} = new Parse::RecDescent( $grammar )  or die }

1;
__END__
=pod
