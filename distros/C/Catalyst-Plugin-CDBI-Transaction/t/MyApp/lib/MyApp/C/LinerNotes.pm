package MyApp::C::LinerNotes;

use strict;
use base 'Catalyst::Base';

sub default : Private {
    my ( $self, $c ) = @_;

    my $linernotess = MyApp::M::CDBI::LinerNotes->retrieve_all;

    my $output = join('|', qw/cdid notes/) . "\n";
    while ( my $linernotes = $linernotess->next ) {
        $output .= join('|', $linernotes, $linernotes->notes) . "\n";
    }

    $c->res->output($output);
}

1;
