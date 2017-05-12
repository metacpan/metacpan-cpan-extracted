#!/usr/bin/perl5.8.8 -w

use strict;
use warnings;

use Test::More tests => 28;

require 't/utils.pl';

use_ok 'Business::SLA';
use_ok 'Business::Hours';

{
    my $sla = new Business::SLA;
    my $bizhours = new Business::Hours;
    $sla->SetBusinessHours($bizhours);
    is $sla->BusinessHours, $bizhours, "Returned same Business Hours";
}
{
    my $bizhours = new Business::Hours;
    my $sla = Business::SLA->new( BusinessHours => $bizhours );
    is $sla->BusinessHours, $bizhours, "Returned same Business Hours";
}

# IsInHours
{
    my $sla = Business::SLA->new( BusinessHours => new Business::Hours );
    ok $sla->IsInHours( get_inhours_time() ), "Time is in business hours";
    ok !$sla->IsInHours( get_outofhours_time() ), "Time is in business hours";
}

# SLA
{
    my $sla = Business::SLA->new(
        BusinessHours => new Business::Hours,
        InHoursDefault => 'in',
        OutOfHoursDefault => 'out',
    );
    is $sla->SLA( get_inhours_time() ), 'in', "is in hours";
    is $sla->SLA( get_outofhours_time() ), 'out', "is out of hours";
}

# AddRealMinutes
{
    my $sla = Business::SLA->new( BusinessHours => new Business::Hours );
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );

    is $sla->AddRealMinutes('real'),     120, "Got real minutes for real SLA";
    is $sla->AddRealMinutes('business'),   0, "Got no real minutes for business SLA";
    is $sla->AddRealMinutes('wrong'),      0, "Got no real minutes for wrong SLA";
    is $sla->AddRealMinutes( undef ),      0, "Got no real minutes for undef SLA";
}

# AddBusinessMinutes
{
    my $sla = Business::SLA->new( BusinessHours => new Business::Hours );
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );

    # with no business minutes set
    is $sla->AddBusinessMinutes('real'), 0, "Got no business minutes for real SLA";
    is $sla->AddBusinessMinutes('business'), 60, "Got business minutes for business SLA";
    is $sla->AddBusinessMinutes('wrong'), 0, "Got no business minutes for wrong SLA";
    is $sla->AddBusinessMinutes(undef), 0, "Got no business minutes for undef SLA";
}

# Starts
{
    my $sla = Business::SLA->new( BusinessHours => new Business::Hours );
    $sla->Add( real => RealMinutes => 120 );
    $sla->Add( business => BusinessMinutes => 60 );
    $sla->Add( immediately_real => RealMinutes => 30, StartImmediately => 1 );
    $sla->Add( immediately_business => RealMinutes => 15, StartImmediately => 1 );

    my $time = get_inhours_time();
    is $sla->Starts( $time, 'real' ), $time, 'in hours => start immediately';
    is $sla->Starts( $time, 'business' ), $time, 'in hours => start immediately';
    is $sla->Starts( $time, 'immediately_real' ), $time, 'in hours => start immediately';
    is $sla->Starts( $time, 'immediately_business' ), $time, 'in hours => start immediately';
    is $sla->Starts( $time, 'wrong' ), $time, 'for wrong levels things start immediately too';

    $time = get_outofhours_time();
    isnt $sla->Starts( $time, 'real' ), $time, 'real: out of hours => start in hours';
    isnt $sla->Starts( $time, 'business' ), $time, 'business: out of hours => start in hours';
    is $sla->Starts( $time, 'immediately_real' ), $time, 'immediately_real: out of hours => start immediately';
    is $sla->Starts( $time, 'immediately_business' ), $time, 'immediately_business: out of hours => start immediately';
    isnt $sla->Starts( $time, 'wrong' ), $time, 'wrong level: out of hours => start in hours too';
}

{
    my $sla = new Business::SLA;
    $sla->Add('aaa', RealMinutes => 120, BusinessMinutes => 60);

    # with no business minutes set
    is $sla->AddBusinessMinutes('aaa'), undef, 
        "Got business minutes for added SLA without Business Hours";

    my $bizhours = new Business::Hours;
    $sla->SetBusinessHours( $bizhours );

    # with no business minutes set
    is $sla->AddBusinessMinutes('aaa'), 60,
        "Got business minutes for added SLA with Business Hours";
}

