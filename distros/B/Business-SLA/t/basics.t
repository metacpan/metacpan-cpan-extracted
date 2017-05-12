#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;

require 't/utils.pl';

use_ok 'Business::SLA';

{
    my $sla = new Business::SLA;
    isa_ok $sla, 'Business::SLA';
    ok !$sla->BusinessHours, 'empty object => empty opt';
    ok !$sla->InHoursDefault, 'empty object => empty opt';
    ok !$sla->OutOfHoursDefault, 'empty object => empty opt';
}

{
    my $sla = new Business::SLA;
    $sla->SetInHoursDefault('aaa');
    is $sla->InHoursDefault, 'aaa', "Returned same InHoursDefault";
}
{
    my $sla = Business::SLA->new( InHoursDefault => 'aaa' );
    is $sla->InHoursDefault, 'aaa', "Returned same InHoursDefault";
}

{
    my $sla = new Business::SLA;
    $sla->SetOutOfHoursDefault('aaa');
    is $sla->OutOfHoursDefault, 'aaa', "Returned same OutOfHoursDefault";
}
{
    my $sla = Business::SLA->new( OutOfHoursDefault => 'aaa' );
    is $sla->OutOfHoursDefault, 'aaa', "Returned same OutOfHoursDefault";
}

# IsInHours
{
    my $sla = new Business::SLA;
    ok $sla->IsInHours( get_inhours_time() ), "Time is in hours";
    ok $sla->IsInHours( get_outofhours_time() ), "Time is in hours";
}

# SLA
{
    my $sla = Business::SLA->new( InHoursDefault => 'in', OutOfHoursDefault => 'out' );
    is $sla->SLA( get_inhours_time() ), 'in', "No business hours => always in hours";
    is $sla->SLA( get_outofhours_time() ), 'in', "No business hours => always in hours";
}

# AddRealMinutes
{
    my $sla = new Business::SLA;
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );

    is $sla->AddRealMinutes('real'),     120, "Got real minutes for added SLA";
    is $sla->AddRealMinutes('business'),   0, "Got no real minutes for business SLA";
    is $sla->AddRealMinutes('wrong'),      0, "Got no real minutes for wrong SLA";
    is $sla->AddRealMinutes( undef ),      0, "Got no real minutes for undef SLA";
}

# AddBusinessMinutes
{
    my $sla = new Business::SLA;
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );

    # with no business minutes set
    is $sla->AddBusinessMinutes('real'), undef, 
        "Got undef instead of business minutes for any SLA without Business Hours";
    is $sla->AddBusinessMinutes('business'), undef, 
        "Got undef instead of business minutes for any SLA without Business Hours";
    is $sla->AddBusinessMinutes('wrong'), undef, 
        "Got undef instead of business minutes for any SLA without Business Hours";
    is $sla->AddBusinessMinutes(undef), undef, 
        "Got undef instead of business minutes for any SLA without Business Hours";
}

# Starts
{
    my $sla = new Business::SLA;
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );
    $sla->Add( immediately_real => RealMinutes => 30, StartImmediately => 1 );
    $sla->Add( immediately_business => RealMinutes => 15, StartImmediately => 1 );

    my $time = get_inhours_time();
    is $sla->Starts( $time, 'real' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'business' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'immediately_real' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'immediately_business' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'wrong' ), $time, 'for a wrong service level things start immediately too';

    $time = get_outofhours_time();
    is $sla->Starts( $time, 'real' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'business' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'immediately_real' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'immediately_business' ), $time, 'no BusinessHours => things start immediately';
    is $sla->Starts( $time, 'wrong' ), $time, 'for a wrong service level things start immediately too';
}

{
    my $sla = new Business::SLA;
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );

    my $time = get_inhours_time();
    is $sla->Due($time, 'real'), $time + 60*120, "Get starting time";
    is $sla->Due($time, 'business'), $time, "Get starting time";
    is $sla->Due($time, 'wrong'), $time, "Get starting time";

    $time = get_outofhours_time();
    is $sla->Due($time, 'real'), $time + 60*120, "Get starting time";
    is $sla->Due($time, 'business'), $time, "Get starting time";
    is $sla->Due($time, 'wrong'), $time, "Get starting time";
}

