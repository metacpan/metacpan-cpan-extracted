use Test::More tests=>8;
use Time::Local;
use Date::PeriodParser;
use POSIX qw( strftime );
use vars qw( $Date::PeriodParser::TestTime );
{
    # Set the base time we use for tests (Fri Apr 12 22:01:36 2002)
    $Date::PeriodParser::TestTime = $base =
        timelocal( qw(36 1 22 12 3 102 ) );
}

sub slt { scalar localtime timelocal @_ }
sub sl { scalar localtime shift }
sub tl { timelocal @_ }
my ($s, $mn, $h, $d, $m, $y, $wd, $yd, $dst) = localtime($base);
my $to_be = ($dst ? "to be" : "not to be");  # Hamlet operator!
diag "Base time is considered $to_be daylight savings";
diag "Time zone on this machine is " . strftime("%Z", localtime());

%tests = (
        "round about now"  => [ sl( tl( '36', '56', '21', '12', '3', '102' ) ), 
                                sl( tl( '36', '06', '22', '12', '3', '102' ) )
                              ],
                              # Fri Apr 12 21:56:36 2002
                              # Fri Apr 12 22:06:36 2002
"roughly yesterday afternoon" 
                           => [ sl( tl( '00', '30', '11', '11', '3', '102' ) ),
                                sl( tl( '00', '00', '20', '11', '3', '102' ) )
                              ],
                              # Thu Apr 11 11:30:00 2002
                              # Thu Apr 11 20:00:00 2002 
 "around the morning of the day before yesterday" 
                           => [ sl( tl( '00', '00', '22', '9',  '3', '102' ) ),
                                sl( tl( '00', '00', '14', '10', '3', '102' ) )
                              ], 
                              # Tue Apr  9 22:00:00 2002
                              # Wed Apr 10 14:00:00 2002
 "roughly eleven days ago" => [ sl( tl( '00', '00', '12', '30', '2', '102' ) ),
                                sl( tl( '59', '59', '11', '3',  '3', '102' ) )
                              ], 
                              # Sat Mar 30 12:00:00 2002
                              # Wed Apr  3 11:59:59 2002
         );

my($from, $to);
foreach $interval (keys %tests) {
  ($from, $to) = parse_period($interval);
  is(sl($from), $tests{$interval}->[0], "'$interval' start");
  is(sl($to),   $tests{$interval}->[1], "'$interval' end");
}
