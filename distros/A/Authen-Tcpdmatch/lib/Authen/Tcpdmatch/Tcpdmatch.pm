# Copyright (c) 2003 Ioannis Tambouras <ioannis@earthlink.net> .
# All rights reserved.
 
package Authen::Tcpdmatch::Tcpdmatch;

use 5.006;
use strict;
use warnings;
use base qw( Exporter ) ;


BEGIN  {
	my $algorithm =  $ENV{TCPDMATCH} || 'RD' ;
	#my $algorithm =  $ENV{TCPDMATCH} || 'Yapp' ;
	eval "use Authen::Tcpdmatch::Tcpdmatch$algorithm" ;
}


our $VERSION     = '0.07';
our @EXPORT      = qw(  tcpdmatch check);




1;
__END__
=head1 NAME

Authen::Tcpdmatch - Perl extension for parsing  hosts.allow  and  hosts.deny

=head1 SYNOPSIS

  use Authen::Tcpdmatch;
  tcpdmatch(  'ftp',  'red.haw.org'          )
  tcpdmatch(  'ftp',  '192.168.0.1'          )
  tcpdmatch(  'ftp',  'red.haw.org' ,   /etc )

=head1 DESCRIPTION

This module in a front-end to the core functionality of tcpdmatch, which consults hosts.allow
and hosts.deny to decide if service should be granted. 

Its sole purpose is to choose load either TcpdmatchYapp (a yapp parser), or 
TcpdmatchRD ( a RecDescent parser) . In previous releases the default
parser was yapp, but the default is now set to RecDecent since yapp is presently
disabled.

=for hide

The default action is to load
the yapp parser since it is serval times faster than RecDescent, and it 
is a lot easier to make it re-entrant.

Set the environment veriable  TCPDMATCH to "RD" in order to use the RecDescent parser,
or just ingore this module and load  "use  Authen::Tcpdmatch::TcpdmatchRD"  instead.
The use interface is the same for all Authen::Tcpdmatch::Tcpdmatch*  modules.
=end

=over

=item tcpdmatch() 

The first and second arguments
are the requested service and the name of remote host, respectively. The third
(optional) argument indicates the directory of the hosts.* files. (Default is /etc .)

=back

=head2 LIMITATIONS

It does not support shell commands,  client lookups, endpoint patterns, spoofing attacks,
and expansions. If these features are important to you,
perhaps you should be using libwarp.so with Authen::Libwrap .

=head2 EXPORT

tcpdmatch

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

L<Authen::libwrap>.
L<hosts.allow(1)>.

=cut
