# For compatibility with Data::Float, the float_class() and associated functions
# have been added. Here we test those functions.

use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);

my $t = 64;

print "1..$t\n";

my $p_zero = 0;
my $n_zero = H2NV('80000000000000000000000000000000');

my $p_inf = 'inf' + 0;
my $n_inf = $p_inf * -1.0;

my $p_nan = 'inf' / 'inf';
my $n_nan = -('inf' / 'inf');

my $normal = 2.017;
my $subnormal = 0.000000001e-299;

if(float_class($p_zero) eq 'ZERO') {print "ok 1\n"}
else {print "not ok 1\n"}

if(float_class($n_zero) eq 'ZERO') {print "ok 2\n"}
else {print "not ok 2\n"}

if(float_class($p_inf) eq 'INFINITE') {print "ok 3\n"}
else {print "not ok 3\n"}

if(float_class($n_inf) eq 'INFINITE') {print "ok 4\n"}
else {print "not ok 4\n"}

if(float_class($p_nan) eq 'NAN') {print "ok 5\n"}
else {print "not ok 5\n"}

if(float_class($n_nan) eq 'NAN') {print "ok 6\n"}
else {print "not ok 6\n"}

if(float_class($normal) eq 'NORMAL') {print "ok 7\n"}
else {print "not ok 7\n"}

if(float_class($subnormal) eq 'SUBNORMAL') {print "ok 8\n"}
else {print "not ok 8\n"}

##############################################

if(float_is_finite($p_zero)) {print "ok 9\n"}
else {print "not ok 9\n"}

if(float_is_finite($n_zero)) {print "ok 10\n"}
else {print "not ok 10\n"}

if(!float_is_finite($p_inf)) {print "ok 11\n"}
else {print "not ok 11\n"}

if(!float_is_finite($n_inf)) {print "ok 12\n"}
else {print "not ok 12\n"}

if(!float_is_finite($p_nan)) {print "ok 13\n"}
else {print "not ok 13\n"}

if(!float_is_finite($n_nan)) {print "ok 14\n"}
else {print "not ok 14\n"}

if(float_is_finite($normal)) {print "ok 15\n"}
else {print "not ok 15\n"}

if(float_is_finite($subnormal)) {print "ok 16\n"}
else {print "not ok 16\n"}

##############################################

if(!float_is_infinite($p_zero)) {print "ok 17\n"}
else {print "not ok 17\n"}

if(!float_is_infinite($n_zero)) {print "ok 18\n"}
else {print "not ok 18\n"}

if(float_is_infinite($p_inf)) {print "ok 19\n"}
else {print "not ok 19\n"}

if(float_is_infinite($n_inf)) {print "ok 20\n"}
else {print "not ok 20\n"}

if(!float_is_infinite($p_nan)) {print "ok 21\n"}
else {print "not ok 21\n"}

if(!float_is_infinite($n_nan)) {print "ok 22\n"}
else {print "not ok 22\n"}

if(!float_is_infinite($normal)) {print "ok 23\n"}
else {print "not ok 23\n"}

if(!float_is_infinite($subnormal)) {print "ok 24\n"}
else {print "not ok 24\n"}

##############################################

if(float_is_zero($p_zero)) {print "ok 25\n"}
else {print "not ok 25\n"}

if(float_is_zero($n_zero)) {print "ok 26\n"}
else {print "not ok 26\n"}

if(!float_is_zero($p_inf)) {print "ok 27\n"}
else {print "not ok 27\n"}

if(!float_is_zero($n_inf)) {print "ok 28\n"}
else {print "not ok 28\n"}

if(!float_is_zero($p_nan)) {print "ok 29\n"}
else {print "not ok 29\n"}

if(!float_is_zero($n_nan)) {print "ok 30\n"}
else {print "not ok 30\n"}

if(!float_is_zero($normal)) {print "ok 31\n"}
else {print "not ok 31\n"}

if(!float_is_zero($subnormal)) {print "ok 32\n"}
else {print "not ok 32\n"}

##############################################

if(!float_is_nzfinite($p_zero)) {print "ok 33\n"}
else {print "not ok 33\n"}

if(!float_is_nzfinite($n_zero)) {print "ok 34\n"}
else {print "not ok 34\n"}

if(!float_is_nzfinite($p_inf)) {print "ok 35\n"}
else {print "not ok 35\n"}

if(!float_is_nzfinite($n_inf)) {print "ok 36\n"}
else {print "not ok 36\n"}

if(!float_is_nzfinite($p_nan)) {print "ok 37\n"}
else {print "not ok 37\n"}

if(!float_is_nzfinite($n_nan)) {print "ok 38\n"}
else {print "not ok 38\n"}

if(float_is_nzfinite($normal)) {print "ok 39\n"}
else {print "not ok 39\n"}

if(float_is_nzfinite($subnormal)) {print "ok 40\n"}
else {print "not ok 40\n"}

##############################################

if(!float_is_normal($p_zero)) {print "ok 41\n"}
else {print "not ok 41\n"}

if(!float_is_normal($n_zero)) {print "ok 42\n"}
else {print "not ok 42\n"}

if(!float_is_normal($p_inf)) {print "ok 43\n"}
else {print "not ok 43\n"}

if(!float_is_normal($n_inf)) {print "ok 44\n"}
else {print "not ok 44\n"}

if(!float_is_normal($p_nan)) {print "ok 45\n"}
else {print "not ok 45\n"}

if(!float_is_normal($n_nan)) {print "ok 46\n"}
else {print "not ok 46\n"}

if(float_is_normal($normal)) {print "ok 47\n"}
else {print "not ok 47\n"}

if(!float_is_normal($subnormal)) {print "ok 48\n"}
else {print "not ok 48\n"}

##############################################

if(!float_is_subnormal($p_zero)) {print "ok 49\n"}
else {print "not ok 49\n"}

if(!float_is_subnormal($n_zero)) {print "ok 50\n"}
else {print "not ok 50\n"}

if(!float_is_subnormal($p_inf)) {print "ok 51\n"}
else {print "not ok 51\n"}

if(!float_is_subnormal($n_inf)) {print "ok 52\n"}
else {print "not ok 52\n"}

if(!float_is_subnormal($p_nan)) {print "ok 53\n"}
else {print "not ok 53\n"}

if(!float_is_subnormal($n_nan)) {print "ok 54\n"}
else {print "not ok 54\n"}

if(!float_is_subnormal($normal)) {print "ok 55\n"}
else {print "not ok 55\n"}

if(float_is_subnormal($subnormal)) {print "ok 56\n"}
else {print "not ok 56\n"}

##############################################

if(!float_is_nan($p_zero)) {print "ok 57\n"}
else {print "not ok 57\n"}

if(!float_is_nan($n_zero)) {print "ok 58\n"}
else {print "not ok 58\n"}

if(!float_is_nan($p_inf)) {print "ok 59\n"}
else {print "not ok 59\n"}

if(!float_is_nan($n_inf)) {print "ok 60\n"}
else {print "not ok 60\n"}

if(float_is_nan($p_nan)) {print "ok 61\n"}
else {print "not ok 61\n"}

if(float_is_nan($n_nan)) {print "ok 62\n"}
else {print "not ok 62\n"}

if(!float_is_nan($normal)) {print "ok 63\n"}
else {print "not ok 63\n"}

if(!float_is_nan($subnormal)) {print "ok 64\n"}
else {print "not ok 64\n"}
