use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';
use MyDaysInterval;

use DateTime::Moonpig;

# examples from the manual

subtest "synopsis" => sub {
  is(exception {
        no strict 'vars';
        no warnings 'once', 'void';
	$birthday = DateTime::Moonpig->new( year   => 1969,
                                            month  =>    4,
                                            day    =>    2,
                                            hour   =>    2,
                                            minute =>   38,
                                          );
       $now = DateTime::Moonpig->new( time() );

       sprintf "%d\n", $now - $birthday;  # returns number of seconds difference

       $later   = $now + 60;     # one minute later
       $earlier = $now - 2*3600; # two hours earlier

       if ($now->follows($birthday)) { }    # true
       if ($birthday->precedes($now)) { }   # also true
      }, undef, "synopsis compiles and runs");
};

sub hours { $_[0] * 3600 }
subtest "overloading: plus and minus scalar" => sub {
        no warnings 'once';
  my    $birthday = DateTime::Moonpig->new( year   => 1969,
                                            month  =>    4,
                                            day    =>    2,
                                            hour   =>    2,
                                            minute =>   38,
                                            second =>    0,
                                          );

  no strict 'vars';
	$x0    = $birthday + 10;         # 1969-04-02 02:38:10
  is($x0->st, "1969-04-02 02:38:10", "x0");
	$x1    = $birthday - 10;         # 1969-04-02 02:37:50
  is($x1->st, "1969-04-02 02:37:50", "x1");
	$x2    = $birthday + (-10);      # 1969-04-02 02:37:50
  is($x2->st, "1969-04-02 02:37:50", "x2");

	$x3    = $birthday + 100;        # 1969-04-02 02:39:40
  is($x3->st, "1969-04-02 02:39:40", "x3");
	$x4    = $birthday - 100;        # 1969-04-02 02:36:20
  is($x4->st, "1969-04-02 02:36:20", "x4");

        # identical to $birthday + 100
	$x5    = 100 + $birthday;        # 1969-04-02 02:39:40
  is($x5->st, "1969-04-02 02:39:40", "x5");

        # forbidden
  like(exception { $x6    = 100 - $birthday; },
       qr/subtracting a date from a number is forbidden/, "x6");

        # handy technique
	$x7    = $birthday + hours(12);  # 1969-04-02 14:38:00
  is($x7->st, "1969-04-02 14:38:00", "x7");
	$x8    = $birthday - hours(12);  # 1969-04-01 14:38:00
  is($x8->st, "1969-04-01 14:38:00", "x8");
};

subtest "overloading: plus object" => sub {
        no strict 'vars';
        no warnings 'once';

        my $three_days = MyDaysInterval->new(3);

        $y0   = $birthday + $three_days;        # 1969-04-05 02:38:00
        is($y0->st, "1969-04-05 02:38:00", "y0");

        # forbidden
        my $pat = qr/no 'as_seconds' method/;
        like(exception {
          my %arg = (year => 2000, month => 1, day => 1);
          $y1   = $birthday + DateTime->new(%arg); # croaks
        }, $pat, "y1");
        like(exception {
          $y2   = $birthday + $birthday;          # croaks
        }, $pat, "y2");
};

subtest "overloading: minus interval object" => sub {
        no strict 'vars';
        no warnings 'once';

        my $three_days = MyDaysInterval->new(3);

        $z2   = $birthday - $three_days;     # 1969-03-30 02:38:00
        is($z2->st, "1969-03-30 02:38:00", "z2");

	# forbidden
        like(exception {
          $z3   = $three_days - $birthday;     # croaks
        }, qr/subtracting a date from a scalar object/, "z3");
};

subtest "overloading: minus date object" => sub {
        no strict 'vars';
        no warnings 'once';

	$x0   = $birthday + 10;         # 1969-04-02 02:38:10
  is($x0->st, "1969-04-02 02:38:10", "x0");

        $z4   = $x0 - $birthday;         # 10
  is($z4, 10, "z4");
        $z5   = $birthday - $x0;         # -10
  is($z5, -10, "z5");

        package Feb13;                  # Silly example
	sub new {
	  my ($class) = @_;
	  bless [ "DUMMY" ] => $class;
        }
        sub epoch { return 1234567890 } # Feb 13 23:31:30 2009 UTC

        package main;

        my $feb13 = Feb13->new();

        $feb13_dt = DateTime->new( year   => 2009,
                                   month  =>    2,
                                   day    =>   13,
                                   hour   =>   23,
                                   minute =>   31,
                                   second =>   30,
                                   time_zone => "UTC",
                                 );

        $z6   = $birthday - $feb13;     # -1258232010
  is($z6, -1258232010, "z6");
        $z7   = $birthday - $feb13_dt;  # -1258232010
  is($z7, -1258232010, "z7");
        $z8   = $feb13 - $birthday;     # 1258232010
  is($z8, +1258232010, "z8");

        # WATCH OUT - will NOT return 1258232010
        $z9   = $feb13_dt - $birthday;  # returns a DateTime::Duration object
  is(ref $z9, "DateTime::Duration", "z9 is a Datetime::Duration");
};

subtest "DST example" => sub {
  no strict 'vars';
        $a_day    = DateTime::Moonpig->new( year   => 2007,
                                            month  =>    3,
                                            day    =>   11,
                                            hour   =>    1,
                                            minute =>    0,
                                            second =>    0,
                                            time_zone => "America/New_York",
                                          );
	$next_day = $a_day->plus(24*3600);
  is($next_day->hms(":"), "02:00:00", "dst");
};


subtest "number of days in month" => sub {
  is (DateTime::Moonpig->new( year  => 1969,
                              month =>    4,
                              day   =>    2,
                             )
      ->number_of_days_in_month(),
      30, "April 1969 -> 30");
};


done_testing;
