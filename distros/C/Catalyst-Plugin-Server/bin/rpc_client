#!/usr/bin/perl --

use strict;
use Data::Dumper;
use Getopt::Std;
use vars qw[%opts];

require RPC::XML;
require RPC::XML::Client;
require XML::Parser;

getopts( 'hedu:m:p:', \%opts );

$opts{'p'} ||= '3000';
$opts{'u'} ||= 'http://127.0.0.1:'.$opts{p}.'/rpc';
$opts{'m'} ||= 'echo.echo';
$opts{'h'} and die usage();

### ok, so we can't actually get this object *ANY OTHER*
### sodding way :(
{   
    local $^W;
    my $code = XML::Parser::ExpatNB->can('parse_more');
    *XML::Parser::ExpatNB::parse_more = sub {
        my $obj = shift;
        print $_[0].$/ if $main::opts{'d'};
        return $code->( $obj, @_ );
    }
}

my @args    = $opts{'e'} ? eval "@ARGV" : @ARGV;
my $req     = RPC::XML::request->new( $opts{'m'}, @args );

print $req->as_string, $/ if $opts{'d'};
print "\n\n-----------------Output-----------\n";

my $cli = RPC::XML::Client->new( $opts{'u'} );
my $resp = $cli->send_request( $req );


print ref $resp ? Dumper( $resp->value ) : "Error: $resp";

sub usage {
    return qq[
Usage:

    $0 [-d] [-e] [-p PORT] [-u URL] [-m METHOD] ARG, [ARG,...]

    Does an xmlrpc call against an xmlrpc server, 
    giving you back the output.

Options:
    -p  Port number to connect to. Defaults to $opts{p}.
    -u  Full url to post to. Defaults to:
        $opts{u}
    -m  Method call to execute. Defaults to $opts{m}
    -d  Enable debug mode. This prints the sent and 
        received xml.
    -e  Eval \@ARGV before providing it as input to the
        server. This allows you to created more complicated
        arguments, than the default simple list.
    -h  Show this usage message
    
Example:   
    $0 -p 1234 foo bar
    $0 -m complicated.method -e '{ key => value }'
    
    \n];
}    
