package t::Utils;
use strict;
use warnings;

sub import {
    my $class = shift;
    my $pkg   = caller;

    no strict 'refs';
    *{"$pkg\::get_expected_data"} = \&get_expected_data;
    *{"$pkg\::test_pair"} = \&test_pair;
}

sub get_expected_data {
    my $data_type = shift;
    my $file = "./t/config/expected/$data_type.pl";
    return do $file;
}

sub test_pair {
    return +{
        all => +{
            yaml => 'complicated',
            json => 'complicated',
            pl   => 'complicated',
            conf => 'complicated',
            ini  => 'simple',
            xml  => 'simple',
        },
        only_main => +{
            yaml => 'complicated_main_only',
            json => 'complicated_main_only',
            pl   => 'complicated_main_only',
            conf => 'complicated_main_only',
            ini  => 'simple_main_only',
            xml  => 'simple_main_only',
        },
    };
}

1;
