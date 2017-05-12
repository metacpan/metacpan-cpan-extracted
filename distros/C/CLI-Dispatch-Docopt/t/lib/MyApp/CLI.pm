package MyApp::CLI;
use strict;
use warnings;
use Data::Dumper;

sub run {
    my ($self, $opt) = @_;

    warn __PACKAGE__. " run!\n". Dumper($opt);
}

1;
