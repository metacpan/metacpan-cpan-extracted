package App::SeismicUnixGui::gmt::usgsdem_constants;

use Moose;

=head2 sheeet names and their 
		associated numbers 

=cut

my $number_h = {
    'Erwinville'  => 3009129,
    'Lacour'      => 3009112,
    'Morganza'    => 3009120,
    'NewRoads'    => 3009121,
    'PortHudson'  => 3009122,
    'Walls'       => 3009130,
    'Summerville' => 3109215,
};

sub get_number_h {
    my ($self) = @_;
    my $output_number_h = $number_h;
    return ($output_number_h);
}

1;
