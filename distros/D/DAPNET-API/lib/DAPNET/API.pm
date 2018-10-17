use strict;

package DAPNET::API;

use LWP::UserAgent;
use JSON;
use MIME::Base64;
#use LWP::ConsoleLogger::Everywhere ();

=head1 NAME

DAPNET::API - Use the DAPNET API from Perl

=head1 SYNOPSIS

my($dapnetobj) = DAPNET::API->new({
    DAPNET_USERNAME => '<username>',
    DAPNET_PW       => '<password>',
    CALLSIGN        => '<your callsign>'
});

$ret = $dapnetobj->send_rubric_content(<text to send>,<rubric name>.<transmitter group name>,<sequence number 1 - 10>);

$ret = $dapnetobj->send_individual_call(<text>,<destination callsign>,<transmitter group name>,<emergency boolean>));

if ($ret) {
    print('HTTP Error response: '.$ret."\n");
} else {
    print("Message sent\n");
}

=head1 DESCRIPTION

Implementation of the DAPNET REST API in Perl.

=head1 AUTHOR

Simon (G7RZU) <simon@gb7fr.org.uk>

=cut

use vars qw($VERSION);
#Define version
$VERSION = '0.9';

=head1 METHODS

This section describes the methods that are implemented and their use. 

=head2 new

Instantiates new object. Pass a hash reference with options as follows

my($dapnetobj) = DAPNET::API->new({
    DAPNET_USERNAME => '<username>',
    DAPNET_PW       => '<password>',
    CALLSIGN        => '<your callsign>'
    DEBUG           => [0|1]
});

returns an object if sucessful or false if not sucessful

=cut


sub new {
	my($class) = shift;
	my($self) = shift;
	if (!exists($self->{DAPNET_USERNAME}) || !exists($self->{DAPNET_PW}) || !exists($self->{CALLSIGN})) {
        return(0);
	}
	bless($self,$class);
	$self->{_CALL_LEN} = length($self->{CALLSIGN});
	return($self);
};

sub _build_request {
    my($self) = shift;
    my($json) = shift;
    my($type) = shift;
    my($username) = $self->{DAPNET_USERNAME};
    my($pw) = $self->{DAPNET_PW};
    my($uri) = 'http://www.hampager.de:8080/'.$type;
    print("Building HTTP request\n") if($self->{DEBUG});
    my($req) = HTTP::Request->new(
                POST => $uri
	             );
    $req->header(   'Content-Type' => 'application/json',
                    'Authorization'=>'Basic ' . encode_base64($username.':'.$pw)
            );
	
    $req->content( $json );
    return($req);
    
};

sub _json_individual_call {
    my($self) = shift;
    my($text,$to,$txgroup,$emergency) = @_;
    my($jsonobj) = JSON->new;
    print("Building JSON for individual call\n") if($self->{DEBUG});
    my $json = $jsonobj->encode ({
                    'text' => $text,
                    'callSignNames' => [$to],
                    'transmitterGroupNames' => [$txgroup],
                    'emergency' => $emergency
            });
    print("JSON:\n\n$json\n") if($self->{DEBUG});    
    return($json);
};

sub _json_rubric_content {
    my($self) = shift;
    my($text,$rubric,$number) = @_;
print("Building JSON for rubric\n") if($self->{DEBUG}); 
    my($jsonobj) = JSON->new;

    my $json = $jsonobj->encode ({
                    'text'      => $text,
                    'rubricName'=> $rubric,
                    'number'    => $number
            });
    print("JSON:\n\n$json\n")if($self->{DEBUG});   
    return($json);
};

=head2 json_response

    Returns a hash ref to the last JSON response or undef if there is none
    
    $jsonhashref = $jsonobj->json_response;

=cut

sub json_response {
    my($self) = shift;
    print("Return JSON response\n") if($self->{DEBUG});
    return($self->{_JSONRESPONSEREF});
};

=head2 send_individual_call

Send a call to a single callsign 

$ret = $dapnetobj->send_individual_call(<text>,<destination callsign>,<transmitter group name>,<emergency boolean>));

Returns 0 on sucess or the HTTP error string on error. 

=cut

sub send_individual_call {

    my $self = shift;
    my($text,$to,$txgroup,$emergency) = @_;
    print("Send individual call\n") if($self->{DEBUG});
    my($ua) = LWP::UserAgent->new;
    my($jsonresobj) = JSON->new;
    my($i) = 1;
    my($json);
    print("substr length: ".length($text)."\n") if($self->{DEBUG});
    if (length($text) <= (79 - $self->{_CALL_LEN})) { 
        my($json) = $self->_json_individual_call($self->{CALLSIGN}.':'.$text,$to,$txgroup,$emergency);
        my($req) = $self->_build_request($json,'calls');    
        my($res) = $ua->request($req);
        print('Request status line: '.$res->status_line."\n") if($self->{DEBUG}) ;
        if (!$res->is_success) {
            return($res->status_line);
        };
        print('JSON Response: '.$res->decoded_content."\n") if($self->{DEBUG});
        $self->{_JSONRESPONSEREF} = $jsonresobj->decode($res->decoded_content);
    } else {
        while (my $substr = substr($text,0,(76 - $self->{_CALL_LEN}),'')) {
            if ($i == 1) {
                print("substr begining: $substr \n") if($self->{DEBUG});
                $json = $self->_json_individual_call($self->{CALLSIGN}.':'.$substr.'...',$to,$txgroup,$emergency);
            } else {
                print("substr next: $substr \n") if($self->{DEBUG});
                $json = $self->_json_individual_call($self->{CALLSIGN}.':'.'...'.$substr,$to,$txgroup,$emergency);
            };
            my($req) = $self->_build_request($json,'calls');    
            my($res) = $ua->request($req);
            print('Request status line: '.$res->status_line."\n") if($self->{DEBUG});
            if (!$res->is_success) {
               return($res->status_line);
           };
           print('JSON Response: '.$res->decoded_content."\n") if($self->{DEBUG});
           $self->{_JSONRESPONSEREF} = $jsonresobj->decode($res->decoded_content);
    
            $i++;
        };
    
    };
        
    
    return(0);

}

=head2 send_rubric_content

Sends a message to a rubric

$ret = $dapnetobj->send_rubric_content(<text to send>,<rubric name>.<transmitter group name>,<sequence number 1 - 10>,<send call? [0|1]>);

Returns 0 on sucess or the HTTP error string on error. 

=cut


sub send_rubric_content {
   my $self = shift;
    my($text,$rubric,$number,$sendcall) = @_;
    print("Send rubric\n") if($self->{DEBUG});
    my($jsonresobj) = JSON->new;
    my($ua) = LWP::UserAgent->new;
    $ua->timeout(20);
    my($i) = 1;
    my($json);
    print("substr length: ".length($text)."\n") if($self->{DEBUG});
    if (length($text) <= (79 - $self->{_CALL_LEN})) { 
        if ($sendcall) {
            $json = $self->_json_rubric_content($self->{CALLSIGN}.':'.$text,$rubric,$number);
        } else {
            $json = $self->_json_rubric_content($text,$rubric,$number);
        };
        my($req) = $self->_build_request($json,'news');    
        my($res) = $ua->request($req);
        print('Request status line: '.$res->status_line."\n") if($self->{DEBUG});
        if (!$res->is_success) {
            return($res->status_line);
        };
        print('JSON Response: '.$res->decoded_content."\n") if($self->{DEBUG});
        $self->{_JSONRESPONSEREF} = $jsonresobj->decode($res->decoded_content);
        
    } else {
        while (my $substr = substr($text,0,(76 - $self->{_CALL_LEN}),'')) {
            if ($i == 1) {
                print("substr begining: $substr \n") if($self->{DEBUG});
                if ($sendcall) {
                    $json = $self->_json_rubric_content($self->{CALLSIGN}.':'.$substr.'...',$rubric,$number);
                } else {
                    $json = $self->_json_rubric_content($substr.'...',$rubric,$number);
                };
            } else {
                print("substr next: $substr \n") if($self->{DEBUG});
                if ($sendcall) {
                    $json = $self->_json_rubric_content($self->{CALLSIGN}.':'.'...'.$substr,$rubric,$number);
                } else {
                    $json = $self->_json_rubric_content('...'.$substr,$rubric,$number);
                };
            };
            my($req) = $self->_build_request($json,'news');    
            my($res) = $ua->request($req);
            print('Request status line: '.$res->status_line."\n") if($self->{DEBUG});
            if (!$res->is_success) {
               return($res->status_line);
           };
            print('JSON Response: '.$res->decoded_content."\n") if($self->{DEBUG});
            $self->{_JSONRESPONSEREF} = $jsonresobj->decode($res->decoded_content);

            $i++;
        };
    
    };
        
    
    return(0);
};

1;
