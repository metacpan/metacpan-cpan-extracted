## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Client::XmlRpc.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA::CAB XML-RPC server clients

package DTA::CAB::Client::XmlRpc;
use DTA::CAB;
use DTA::CAB::Client;
use RPC::XML;
use RPC::XML::Client;
use DTA::CAB::Datum ':all';
use DTA::CAB::Utils ':all';
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Client);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH ref
##    {
##     ##-- server
##     serverURL => $url,             ##-- default: localhost:8000
##     serverEncoding => $encoding,   ##-- default: UTF-8
##     timeout => $timeout,           ##-- timeout in seconds, default: 300 (5 minutes)
##
##     ##-- debugging
##     tracefh => $fh,                ##-- dump requests to $fh if defined (default=undef)
##     testConnect => $bool,          ##-- if true connected() will send a test query (default=true)
##
##     ##-- underlying RPC::XML client
##     xcli => $xcli,                 ##-- RPC::XML::Client object
##    }
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- server
			   serverURL      => 'http://localhost:8000',
			   serverEncoding => 'UTF-8', ##-- default server encoding
			   timeout => 300,
			   testConnect => 1,
			   ##
			   ##-- RPC::XML stuff
			   xcli => undef,
			   xargs => {
				     compress_requests => 0,    ##-- send compressed requests?
				     compress_thresh   => 8192, ##-- byte limit for compressed requests
				     ##
				     message_file_thresh => 0,  ##-- disable file-based message spooling
				    },
			   ##
			   ##-- user args
			   @_,
			  );
}

##==============================================================================
## Methods: Generic Client API: Connections
##==============================================================================

## $bool = $cli->connected()
sub connected {
  my $cli = shift;
  return 0 if (!$cli->{xcli});
  return 1 if (!$cli->{testConnect});

  ##-- send a test query (system.identity())
  my $req = $cli->newRequest('system.identity');
  my $rsp = $cli->{xcli}->send_request( $req );
  return ref($rsp) ? 1 : 0;
}

## $bool = $cli->connect()
##  + establish connection
sub connect {
  my $cli = shift;
  $cli->{xcli} = RPC::XML::Client->new($cli->{serverURL}, %{$cli->{xargs}})
    or $cli->logdie("could not create underlying RPC::XML::Client: $!");
  $cli->{xcli}->message_file_thresh(0)
    if (defined($cli->{xargs}{message_file_thresh}) && !$cli->{xargs}{message_file_thresh});
  $cli->{xcli}->useragent->timeout($cli->{timeout})
    if (defined($cli->{timeout}));
  return $cli->connected();
}

## $bool = $cli->disconnect()
sub disconnect {
  my $cli = shift;
  delete($cli->{xcli});
  return 1;
}

## @analyzers = $cli->analyzers()
sub analyzers {
  my $rsp = $_[0]->request( RPC::XML::request->new('dta.cab.listAnalyzers') );
  return ref($rsp) && !$rsp->is_fault ? sort(@{ $rsp->value }) : $rsp;
}

##==============================================================================
## Methods: Utils
##==============================================================================

## $rsp_or_error = $cli->request($req)
## $rsp_or_error = $cli->request($req, $doDeepEncoding=1)
##  + send XML-RPC request, log if error occurs
sub request {
  my ($cli,$req,$doRecode) = @_;

  ##-- cache RPC::XML encoding
  $doRecode   = 1 if (!defined($doRecode));
  my $enc_tmp = $RPC::XML::ENCODING;
  $RPC::XML::ENCODING = $cli->{serverEncoding};

  $cli->connect() if (!$cli->{xcli});
  $req = DTA::CAB::Utils::deep_encode($cli->{serverEncoding}, $req) if ($doRecode);
  $cli->{tracefh}->print($req->as_string) if (defined($cli->{tracefh})); ##-- trace

  my $rsp = $cli->{xcli}->send_request( $req );
  if (!ref($rsp)) {
    $cli->error("RPC::XML::Client::send_request() failed:");
    $cli->error($rsp);
  }
  elsif ($rsp->is_fault) {
    $cli->error("XML-RPC fault (".$rsp->code.") ".$rsp->string);
  }

  ##-- cleanup & return
  $RPC::XML::ENCODING = $enc_tmp;
  return $doRecode ? DTA::CAB::Utils::deep_decode($cli->{serverEncoding}, $rsp) : $rsp;
}


##==============================================================================
## Methods: Generic Client API: Queries: v0.x
##==============================================================================

## $req = $cli->newRequest($methodName, @args)
##  + returns new RPC::XML::request
##  + encodes all elementary data types as strings
sub newRequest {
  my ($cli,$method,@args) = @_;
  my $str_tmp = $RPC::XML::FORCE_STRING_ENCODING;
  $RPC::XML::FORCE_STRING_ENCODING = 1;
  my $req = RPC::XML::request->new($method,@args);
  $RPC::XML::FORCE_STRING_ENCODING = $str_tmp;
  return $req;
}

## $tok = $cli->analyzeToken($analyzer, $tok, \%opts)
sub analyzeToken {
  my ($cli,$aname,$tok,$opts) = @_;
  my $suffix = $opts && $opts->{methodSuffix} ? $opts->{methodSuffix} : ''; ##-- e.g. methodSuffix=>1" for v1.x interface
  my $rsp = $cli->request($cli->newRequest("$aname.analyzeToken${suffix}",
					   $tok,
					   (defined($opts) ? $opts : qw())
					  ));
  return ref($rsp) && !$rsp->is_fault ? toToken($rsp->value) : $rsp;
}

## $sent = $cli->analyzeSentence($analyzer, $sent, \%opts)
sub analyzeSentence {
  my ($cli,$aname,$sent,$opts) = @_;
  my $suffix = $opts && $opts->{methodSuffix} ? $opts->{methodSuffix} : '';  ##-- e.g. methodSuffix=>1" for v1.x interface
  my $rsp = $cli->request($cli->newRequest("$aname.analyzeSentence${suffix}",
					   $sent,
					   (defined($opts) ? $opts : qw())
					  ));
  return ref($rsp) && !$rsp->is_fault ? toSentence($rsp->value) : $rsp;
}

## $doc = $cli->analyzeDocument($analyzer, $doc, \%opts)
sub analyzeDocument {
  my ($cli,$aname,$doc,$opts) = @_;
  my $suffix = $opts && $opts->{methodSuffix} ? $opts->{methodSuffix} : ''; ##-- e.g. methodSuffix=>1" for v1.x interface
  my $rsp = $cli->request($cli->newRequest("$aname.analyzeDocument${suffix}",
					   $doc,
					   (defined($opts) ? $opts : qw())
					  ));
  return ref($rsp) && !$rsp->is_fault ? toDocument($rsp->value) : $rsp;
}

## $data_str = $cli->analyzeData($analyzer, $input_str, \%opts)
sub analyzeData {
  my ($cli,$aname,$data,$opts) = @_;
  my $rsp = $cli->request($cli->newRequest("$aname.analyzeData",
					   RPC::XML::base64->new($data),
					   (defined($opts) ? $opts : qw())
					  ),
			  0 ##-- no deep encode/decode
			 );
  return ref($rsp) && !$rsp->is_fault ? $rsp->value : $rsp;
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Client::XmlRpc - DTA::CAB XML-RPC server clients

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Client::XmlRpc;
 
 ##========================================================================
 ## Constructors etc.
 
 $cli = DTA::CAB::Client::XmlRpc->new(%args);
 
 ##========================================================================
 ## Methods: Generic Client API: Connections
 
 $bool = $cli->connected();
 $bool = $cli->connect();
 $bool = $cli->disconnect();
 @analyzers = $cli->analyzers();
 
 ##========================================================================
 ## Methods: Utils
 
 $rsp_or_error = $cli->request($req);
 
 ##========================================================================
 ## Methods: Generic Client API: Queries
 
 $req  = $cli->newRequest($methodName, @args);
 $tok  = $cli->analyzeToken($analyzer, $tok, \%opts);
 $sent = $cli->analyzeSentence($analyzer, $sent, \%opts);
 $doc  = $cli->analyzeDocument($analyzer, $doc, \%opts);


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::XmlRpc: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Client::XmlRpc
inherits from
L<DTA::CAB::Client|DTA::CAB::Client>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::XmlRpc: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $cli = CLASS_OR_OBJ->new(%args);

Constructor.

%args, %$cli:

 ##-- server selection
 serverURL      => $url,         ##-- default: localhost:8000
 serverEncoding => $encoding,    ##-- default: UTF-8
 timeout        => $timeout,     ##-- timeout in seconds, default: 300 (5 minutes)
 ##
 ##-- underlying RPC::XML client
 xcli           => $xcli,        ##-- RPC::XML::Client object

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::XmlRpc: Methods: Generic Client API: Connections
=pod

=head2 Methods: Generic Client API: Connections

=over 4

=item connected

 $bool = $cli->connected();

Override: returns true iff $cli is connected to a server.

=item connect

 $bool = $cli->connect();

Override: establish connection to the selected server.

=item disconnect

 $bool = $cli->disconnect();

Override: close current server connection, if any.

=item analyzers

 @analyzers = $cli->analyzers();

Override: get list of known analyzers from the server.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::XmlRpc: Methods: Utils
=pod

=head2 Methods: Utils

=over 4

=item request

 $rsp_or_error = $cli->request($req);
 $rsp_or_error = $cli->request($req, $doDeepEncoding=1)

Send an XML-RPC request $req, log if error occurs.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::XmlRpc: Methods: Generic Client API: Queries
=pod

=head2 Methods: Generic Client API: Queries

=over 4

=item newRequest

 $req = $cli->newRequest($methodName, @args);

Returns new RPC::XML::request for $methodName(@args).
Encodes all atomic data types as strings

=item analyzeToken

 $tok = $cli->analyzeToken($analyzer, $tok, \%opts);

Override: server-side token analysis.

=item analyzeSentence

 $sent = $cli->analyzeSentence($analyzer, $sent, \%opts);

Override: server-side sentence analysis.

=item analyzeDocument

 $doc = $cli->analyzeDocument($analyzer, $doc, \%opts);

Override: server-side document analysis.

=item analyzeData

 $data_str = $cli->analyzeData($analyzer, $input_str, \%opts)

Override: server-side raw-data analysis.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
