package DataEcho;

# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)


=head1 NAME
    DataEcho
        
==head1 DESCRIPTION    

    Service class used in conjusction with basic.pl
    
    All AMF::Perl service classes must define the method table, where the user can supply optional description and return type.

	If you want to return an error message, handled by functionName_onStatus in the Flash client (as opposed to functionName_onResult, which is normal), include

use AMF::Perl qw/amf_throw/;

and then call amf_throw() with a string or an arbitrary object as a parameter.


==head1 CHANGES

Tue Jul  6 22:06:56 EDT 2004
Added exception throwing via amf_throw().

Sun Apr  6 14:24:00 EST 2003
Created after AMF-PHP.

=cut

use AMF::Perl qw/amf_throw/;



sub new
{
    my ($proto)=@_;
    my $self={};
    bless $self, $proto;
    return $self;
}


sub methodTable
{
    return {
        "echoNormal" => {
            "description" => "Echoes the passed argument back to Flash (no need to set the return type)",
            "access" => "remote", # available values are private, public, remote
        },
        "echoDate" => {
            "description" => "Echoes a Flash Date Object (the returnType needs setting)",
            "access" => "remote", # available values are private, public, remote
            "returns" => "date"
        },
        "echoXML" => {
            "description" => "Echoes a Flash XML Object (the returnType needs setting)",
            "access" => "remote", # available values are private, public, remote
            "returns" => "xml"
        },
        "generateError" => {
            "description" => "Throw an error so that _status, not _result on the client side is called",
            "access" => "remote", # available values are private, public, remote
        },
    };
}

sub echoNormal
{
    my ($self, $data) = @_;
    return $data;
}
sub echoDate
{
    my ($self, $data) = @_;
    return $data;
}
sub echoXML
{
    my ($self, $data) = @_;
    return $data;
}

#This function will NOT return the value, because the call to amf_throw() will interrupt
#the control flow and cause the _Status function on the client to be called.
sub generateError
{
    my ($self, $data) = @_;
    amf_throw("An error!!!");
    return "No error";
}

1;
