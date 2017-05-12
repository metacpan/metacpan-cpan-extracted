package MyApp::CLI::Bar;
use strict;
use warnings;

sub main {
    my ($class, $c) = @_;

    my $opt;

    $c->parse_opt(
        'option=s' => \$opt->{option},
    )->setopt($opt);

    print $c->getopt('option');
}

1;
