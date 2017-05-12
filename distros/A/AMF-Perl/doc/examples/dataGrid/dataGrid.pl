#!/usr/bin/perl -w
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

#This is a server-side script that responds to an Macromedia Flash client 
#talking in ActionScript. See the AMF::Perl project site (http://www.simonf.com/amfperl) 
#for more information.

#You can pass arguments from your Flash code to the perl script.

use strict;
use lib '/var/www/libperl';

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

package DataGridModel;

sub new
{
    my ($proto)=@_;
    my $self={};
    bless $self, $proto;
    return $self;
}

sub getData
{
    my ($self, $arg1, $arg2) = @_;
    my @array;
    my %hash = ("From" => 'Simon', "Subject" =>'AMF::Perl presentation', "URL" => "http://www.simonf.com");
    push @array, \%hash;
    my %hash1 = ("From" => 'Adrian', "Subject" =>'GUI in Flash', "URL" => "http://www.dnalc.org");
    push @array, \%hash1;
    my %hash2 = ("From" => 'James', "Subject" =>'How to get here from Penn station', "URL" => "http://www.cpan.org");
    push @array, \%hash2;
    return \@array;
    }
    
my $gateway = AMF::Perl->new;
$gateway->registerService("DataGrid",new DataGridModel());
$gateway->service();

