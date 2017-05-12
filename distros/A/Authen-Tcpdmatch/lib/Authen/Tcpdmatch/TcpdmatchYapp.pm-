# Copyright (c) 2003 Ioannis Tambouras <ioannis@earthlink.net> .
# All rights reserved.


package Authen::Tcpdmatch::TcpdmatchYapp;

use Attribute::Handlers;
use Parse::Lex;
use Authen::Tcpdmatch::YappParser;
use Authen::Tcpdmatch::Lexer;
use base 'Exporter' ;

our $VERSION = '0.03';
our @EXPORT  = qw( tcpdmatch check );

my ($debug, $n) = 0;

my Authen::Tcpdmatch::Lexer  $l : Lexer  or die( $!) ;

sub Walker  {
         $l->nextis( \$n ) ;
         return ('',undef)  if $l->eoi;
	 print $n->name, '    ', $n->text   if $debug;
	 ($n->name, $n->text);
}
	 
my $err = sub { print "illegal_token:  ", $_[0]->YYCurtok , "  ( ", $_[0]->YYCurval, " )"  };
	

sub check {
        my ( $input, $service, $remote ) = @_ ;
	$l->from( $input );
	my $p = new  Authen::Tcpdmatch::YappParser ( yylex =>  \&Walker, yyerror=> $err,  ) or die;
	$p->{USER}{service} = $service;
	$p->{USER}{remote}  = $remote;
	$p->YYParse ;
}

sub check_file {
        my ($service, $remote, $file)  = @_;
        local undef $/ ,  open (my $fh , $file)   or return ;
        check( scalar <$fh> ,  $service , $remote );
}


sub tcpdmatch ($$;$)  {
        my ( $service, $remote, $dir) = @_ ;
        (check_file    $service,  $remote,  ($dir ||'/etc') . "/hosts.allow" )    or
        ! (check_file  $service,  $remote,  ($dir ||'/etc') . "/hosts.deny")      or   undef;
}

 


1;
__END__
=head1 NAME

Authen::Tcpdmatch::TcpdmatchYapp -   Tcpdmatch Parser based on Parse::Yapp

=head1 SYNOPSIS

  use Authen::Tcpdmatch::TcpdmatchYapp;
  tcpdmatch(  'ftp',  'red.haw.org'          )
  tcpdmatch(  'ftp',  '192.168.0.1'          )
  tcpdmatch(  'ftp',  'red.haw.org' ,   /etc )

=head1 DESCRIPTION

This module implements the core functionality of tcpdmatch using a Yapp parser;
it consults hosts.allow and hosts.deny to decide if service should be granted.

Due to its tiny size (2k bytes), this module is best suited for embedded environments,
or to modules that need this type of authentication.
Although this is not a full-feature implementation of tcpdmatch(1),
it supports the following capabilities:

 A. ALL and LOCAL wildcards.
 B. Recursive EXCEPT  modifier
 C. Leading and trailing dot patterns
 D. Netmasks
 E. Skipping lines with faulty syntax, comments, or blanks

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

It is not re-entrant.

=head2 EXPORT

tcpdmatch

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

L<Authen::libwrap>.
L<hosts.allow(1)>.

=cut
