package AETest;

use strict;
use warnings;
use App::EditorTools;
use App::Cmd::Tester;

sub test {
    my $class = shift;
    my ( $args, $input ) = @_;
    close STDIN;
    open( STDIN, '<', \$input ) or die "Couldn't redirect STDIN";
    my $return = test_app( 'App::EditorTools', @_ );
    return $return;
}

1;
