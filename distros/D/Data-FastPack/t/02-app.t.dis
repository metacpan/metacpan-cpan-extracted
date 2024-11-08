# Create an app
use warnings; 
use strict;

use Test::More;
use Data::FastPack::App;


use Data::JPack;


use File::Temp qw<tempdir>;
my $html_container//=tempdir(CLEANUP=>1);


Data::FastPack::App::add_to_jpack_container $html_container;

my $prefix="app/jpack/main";

ok -e "$html_container/$prefix/00000000000000000000000000000000/00000000000000000000000000000000.jpack";

# Encode data.
#$jpack->encode("SOME DATA");




done_testing;
