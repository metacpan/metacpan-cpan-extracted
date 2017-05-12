#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

eval { require Bit::Vector; };

if ($@)
{
    print "1..0\n";
    exit 0;
}

require Date::Pcalendar;
require Date::Pcalendar::Profiles;

Date::Pcalendar::Profiles->import('$Profiles');

# ======================================================================
#   $cal  = Date::Pcalendar->new($prof);
#   $year = $cal->year($year);
#   $year = Date::Pcalendar::Year->new($year,$prof); # (implicitly)
# ======================================================================

print "1..", scalar(keys %{$Profiles}), "\n";

$n = 1;

$year = 2000;

foreach $key (keys %{$Profiles})
{
    eval
    {
        $cal  = Date::Pcalendar->new( $Profiles->{$key} );
        $year = $cal->year( $year );
    };
    unless ($@)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

