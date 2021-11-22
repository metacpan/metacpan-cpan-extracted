#usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm qw( check_water_filter reduce_precision );
use Acme::FishFarm::WaterFiltration;

my $water_filter = Acme::FishFarm::WaterFiltration->install;

say "Water filter installed and switched on!\n";

while ( "Fish are living under the water..." ) {
    check_water_filter( $water_filter, int (rand(150)), reduce_precision( rand(10) ) );
    sleep(1);
    say "";
}

=head1 use Acme::FishFarm's check_water_filter
sub check_water_filter {
    my ( $water_filter, $current_reading ) = @_;
    my $waste_threshold = $water_filter->waste_count_threshold;
    
    $water_filter->current_waste_count( $current_reading );
    
    print "Current Waste Count: ", $current_reading, " (high: >= ", $waste_threshold, ")\n";

    if ( $water_filter->is_cylinder_dirty ) {
        print "  !! Filtering cylinder is dirty!\n";
        print "  Cleaned the filter!\n";
        $water_filter->clean_cylinder;
    } else {
        print "  Filtering cylinder is still clean.\n";
    }
    1;
}
=cut
# besiyata d'shmaya



