use strict; 
use warnings; 
use Test::More;
use DateTime::Astro qw/new_moon_after/; 
use DateTime; 
use Time::HiRes qw(time);

my $dt = DateTime->today(time_zone=>'Asia/Tokyo'); 
my $diff = 1;
for my $i (0..200) { 
    note "new moon after $dt";
    my $start = time();
    my $p = new_moon_after( $dt ); 
    my $end = time();
    ok( ($end - $start) < 1, "elapsed time is less than $diff (" . ($end-$start). ")");
    $dt = $p; 
} 

done_testing;