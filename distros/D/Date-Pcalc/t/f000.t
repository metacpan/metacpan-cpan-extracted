#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

# ======================================================================
#   $version = $Carp::Clan::VERSION;
#   $version = $Date::Pcalc::VERSION;
#   $version = &Date::Pcalc::Version();
#   $version = $Date::Pcalc::Object::VERSION;
#   $version = $Date::Pcalendar::Profiles::VERSION;
#   $version = $Date::Pcalendar::Year::VERSION;
#   $version = $Date::Pcalendar::VERSION;
# ======================================================================

$Carp::Clan::VERSION                = $Carp::Clan::VERSION                = 0;
$Date::Pcalc::VERSION               = $Date::Pcalc::VERSION               = 0;
$Date::Pcalc::Object::VERSION       = $Date::Pcalc::Object::VERSION       = 0;
$Date::Pcalendar::Profiles::VERSION = $Date::Pcalendar::Profiles::VERSION = 0;
$Date::Pcalendar::Year::VERSION     = $Date::Pcalendar::Year::VERSION     = 0;
$Date::Pcalendar::VERSION           = $Date::Pcalendar::VERSION           = 0;
$Bit::Vector::VERSION               = $Bit::Vector::VERSION               = 0;

$tests = 9;

eval { require Bit::Vector; };

unless ($@) { $tests += 6; }

print "1..$tests\n";

$n = 1;

eval
{
    require Carp::Clan;
    Carp::Clan->import( qw(^Date::) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Carp::Clan::VERSION >= 5.3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Pcalc;
    Date::Pcalc->import( qw(:all) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Pcalc::VERSION eq '6.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (&Date::Pcalc::Version() eq '6.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Pcalc::Object;
    Date::Pcalc::Object->import( qw(:all) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Pcalc::Object::VERSION eq '6.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Pcalendar::Profiles;
    Date::Pcalendar::Profiles->import( qw( $Profiles ) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Pcalendar::Profiles::VERSION eq '6.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit 0 if $n > $tests;

if ($Bit::Vector::VERSION >= '7.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (&Bit::Vector::Version() >= '7.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Pcalendar::Year;
    Date::Pcalendar::Year->import( qw(:all) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Pcalendar::Year::VERSION eq '6.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Pcalendar;
    Date::Pcalendar::Year->import( qw() );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Pcalendar::VERSION eq '6.1')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

