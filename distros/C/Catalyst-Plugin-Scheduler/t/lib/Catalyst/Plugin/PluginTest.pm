package Catalyst::Plugin::PluginTest;

use strict;
use warnings;

use MRO::Compat;
Class::C3::initialize();

sub setup {
    my $c = shift;
    $c->maybe::next::method(@_);
    
    if ( $c->can('schedule') ) {
        $c->schedule(
            at    => '* * * * *',
            event => \&plugin_test,
        );
    }
}

sub plugin_test {
    my $c = shift;
    
    # write out a file so the test knows we did something
    my $fh = IO::File->new( $c->path_to( 'plugin_test.log' ), 'w' )
        or die "Unable to write log file: $!";
    close $fh;
}

1;

