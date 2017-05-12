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

$Date::Pcalendar::Profiles::Profiles =
$Date::Pcalendar::Profiles::Profiles = 0; # Avoid "used only once" warning

require Date::Pcalc::Object;
require Date::Pcalendar::Profiles;
require Date::Pcalendar;

Date::Pcalc::Object->import(':all');

# ======================================================================
#   $cal = Date::Pcalendar->new(PROFILE[,LANG[,WEEKEND]]);
#   $cal->cache_add( YEAR [,YEAR]* );
#   $cal->cache_del( YEAR [,YEAR]* );
#   @list = $cal->cache_keys();
#   @dates = $cal->search(SUBSTRING);
#   @labels = $cal->labels(DATE);
#   @dates = $year->search(SUBSTRING);
#   @labels = $year->labels(DATE);
# ======================================================================

print "1..6\n";

$n = 1;

Date::Pcalc->date_format(3);

$cal = Date::Pcalendar->new( $Date::Pcalendar::Profiles::Profiles->{'DE-NW'}, Language(Decode_Language("Deutsch")) );

$cal->cache_add( 2000..2003,2005 );

@list = $cal->cache_keys();

if (join(',', @list) eq '2000,2001,2002,2003,2005')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$cal->cache_del( 2005 );

@list = $cal->cache_keys();

if (join(',', @list) eq '2000,2001,2002,2003')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@date = $cal->search("Weiber");

$string = join( '', map( sprintf( "%s (%s)\n", $_, join( ' ', sort $cal->labels($_->date()) ) ), @date ) );

if ($string eq <<'VERBATIM')
Donnerstag, den 2. März 2000 (Donnerstag Fettdonnerstag Weiberfastnacht)
Donnerstag, den 22. Februar 2001 (Donnerstag Fettdonnerstag Weiberfastnacht)
Donnerstag, den 7. Februar 2002 (Donnerstag Fettdonnerstag Weiberfastnacht)
Donnerstag, den 27. Februar 2003 (Donnerstag Fettdonnerstag Weiberfastnacht)
VERBATIM
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$check = join( '', map( sprintf( "%s (%s)\n", $_, join( ' ', sort $cal->year($_)->labels($_->date()) ) ), @date ) );

if ($check eq <<'VERBATIM')
Donnerstag, den 2. März 2000 (Donnerstag Fettdonnerstag Weiberfastnacht)
Donnerstag, den 22. Februar 2001 (Donnerstag Fettdonnerstag Weiberfastnacht)
Donnerstag, den 7. Februar 2002 (Donnerstag Fettdonnerstag Weiberfastnacht)
Donnerstag, den 27. Februar 2003 (Donnerstag Fettdonnerstag Weiberfastnacht)
VERBATIM
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = $cal->year( 2004 );

@date = $year->search("Weiber");

$string = join( '', map( sprintf( "%s (%s)\n", $_, join( ' ', sort $cal->labels($_) ) ), @date ) );

if ($string eq <<'VERBATIM')
Donnerstag, den 19. Februar 2004 (Donnerstag Fettdonnerstag Weiberfastnacht)
VERBATIM
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$check = join( '', map( sprintf( "%s (%s)\n", $_, join( ' ', sort $year->labels($_) ) ), @date ) );

if ($check eq <<'VERBATIM')
Donnerstag, den 19. Februar 2004 (Donnerstag Fettdonnerstag Weiberfastnacht)
VERBATIM
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

