use Test::Simple tests => 1;

use lib '../blib/lib','../blib/arch';

use Algorithm::RandomPointGenerator;

# Test 1 (Data Generation):

open HISTFILE, ">__temphist.csv";
foreach my $i (0..9) {
    print HISTFILE "1,1,1,0,0,0,0,0,0,0\n";
}
close HISTFILE;
open BBFILE, ">__tempbb.csv";
foreach my $i (0..1) {
    print BBFILE "-10, 10\n";
}
close BBFILE;

my $generator = Algorithm::RandomPointGenerator->new(
                            input_histogram_file     => '__temphist.csv',
                            bounding_box_file        => '__tempbb.csv',
                            number_of_points         => 50,
                            how_many_to_discard      => 50,
                );
eval{
    $generator->read_histogram_file_for_desired_density();
    $generator->read_file_for_bounding_box();
    $generator->normalize_input_histogram();
    $generator->set_sigmas_for_proposal_density();
    $generator->metropolis_hastings();
    $generator->make_output_histogram_for_generated_points();
    my $pause_time = 3;
    $generator->plot_histogram_lineplot($pause_time);
};
print ${$@} if ($@); 

ok( !$@,  'RandomPointGenerator works' );

unlink "__temphist.csv";
unlink "__tempbb.csv";
