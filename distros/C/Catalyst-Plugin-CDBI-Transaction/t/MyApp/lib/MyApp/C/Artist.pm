package MyApp::C::Artist;

use strict;
use base 'Catalyst::Base';

sub default : Private {
    my ( $self, $c ) = @_;

    my $artists = MyApp::M::CDBI::Artist->retrieve_all;

    my $output = join('|', qw/artistid name/) . "\n";
    while ( my $artist = $artists->next ) {
        $output .= join('|', $artist, $artist->name) . "\n";
    }

    $c->res->output($output);
}

1;
