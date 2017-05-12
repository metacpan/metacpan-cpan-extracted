use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Try::Tiny;

use DateTime::Moonpig;
warn "DateTime version: " . DateTime->VERSION . "\n";

sub jan {
  my ($day) = @_;
  DateTime::Moonpig->new( year => 2000, month => 1, day => $day );
}

my $dt = jan(1);

subtest "mutators" => sub {
  for my $no (qw(
                  add_duration
                  subtract_duration

                  truncate

                  set

                  set_year
                  set_month
                  set_day
                  set_hour
                  set_minute
                  set_second
                  set_nanosecond

               )) {
    like(exception { $dt->$no() },
         qr/^Do not mutate DateTime objects!/,
         "$no method should fail");
  }
};

sub SC::as_seconds { 1 }

subtest "arithmetic" => sub {
  my $dummy = bless {} => 'BLARF';
  my $sc = bless {} => 'SC';

  like(exception { $dt + {} },
       qr/Can't add .* to unblessed HASH reference/,
       "adding a nondate");

  like(exception { $dt + $dummy },
       qr/Can't add .* to object with no 'as_seconds' method/,
       "adding a bad object");

  like(exception { $dt + $dt },
       qr/Can't add .* to object with no 'as_seconds' method/,
       "adding another DTM");

  like(exception { $dt - {} },
       qr/Can't subtract unblessed HASH reference/,
       "subtracting a nondate");

  like(exception { $dt - $dummy },
       qr/Can't subtract X from .* when X has neither/,
       "subtracting a bad object");

  like(exception { 17 - $dt },
       qr/subtracting a date from a number/,
       "subtraction wrong order");

  like(exception { $sc - $dt },
       qr/subtracting a date from a scalar object/,
       "subtraction wrong order");

  is(exception { $dt - 17 }, undef, "subtraction right order (number)");
  is(exception { $dt - $sc }, undef, "subtraction right order (scalar)");
};


done_testing;
