#!/usr/bin/perl -w
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

#This is a server-side script that responds to an Macromedia Flash client 
#talking in ActionScript. See the FLAP project site (http://www.simonf.com/amfperl) 
#for more information.

use strict;

=head1 COMMENT
        
    ActionScript for this service:

    #include "NetServices.as"
    #include "NetDebug.as"

    conn = NetServices.setDefaultGatewayURL("http:#host/cpu.pl");
    conn = NetServices.createGatewayConnection();

    connection = NetServices.createGatewayConnection();

    remoteService = connection.getService("CpuUsage", this);

    remoteService.getCpuUsage();
=cut

use AMF::Perl;

package cpuUsage;

sub new
{
    my ($proto)=@_;
    my $self={};
    bless $self, $proto;
    return $self;
}

sub getCpuUsage
{
    my $output = `uptime`;
    my @tokens = split /\s+/, $output;
    #Remove commas.
    @tokens = map {s/,//g; $_} @tokens;
    
    my @array;
    my %hash = ("Name" => 'L 1', "Value" => $tokens[10]);
    push @array, \%hash;
    my %hash1 = ("Name" => 'L 5', "Value" => $tokens[11]);
    push @array, \%hash1;
    my %hash2 = ("Name" => 'L 15', "Value" => $tokens[12]);
    push @array, \%hash2;
    return \@array;
    }
    
my $gateway = AMF::Perl->new;
$gateway->registerService("CpuUsage",new cpuUsage());
$gateway->service();

