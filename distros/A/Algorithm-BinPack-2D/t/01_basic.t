# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Test::More;
use Algorithm::BinPack::2D;

subtest 'Basic algorithm' => sub {
    my $packer = Algorithm::BinPack::2D->new(
        binwidth  => 500,
        binheight => 400,
    );

    $packer->add_item(label => 'one',   width => 300, height => 100);
    $packer->add_item(label => 'two',   width => 200, height => 100);
    $packer->add_item(label => 'three', width => 100, height => 200);
    $packer->add_item(label => 'four',  width => 100, height => 200);
    $packer->add_item(label => 'five',  width => 200, height => 100);
    $packer->add_item(label => 'six',   width => 300, height => 300);
    $packer->add_item(label => 'seven', width => 200, height => 100);
    $packer->add_item(label => 'eight', width => 450, height => 350);

    my @bins = $packer->pack_bins;
    is_deeply(
        \@bins,
        [
            {
                'width'  => 450,
                'height' => 350,
                'items'  => [
                    {
                        'width'  => 450,
                        'y'      => 0,
                        'label'  => 'eight',
                        'x'      => 0,
                        'height' => 350
                    }
                ]
            },
            {
                'width'  => 500,
                'height' => 400,
                'items'  => [
                    {
                        'width'  => 300,
                        'y'      => 0,
                        'label'  => 'six',
                        'x'      => 0,
                        'height' => 300
                    },
                    {
                        'width'  => 300,
                        'y'      => 300,
                        'label'  => 'one',
                        'x'      => 0,
                        'height' => 100
                    },
                    {
                        'width'  => 200,
                        'y'      => 0,
                        'label'  => 'five',
                        'x'      => 300,
                        'height' => 100
                    },
                    {
                        'width'  => 200,
                        'y'      => 100,
                        'label'  => 'seven',
                        'x'      => 300,
                        'height' => 100
                    },
                    {
                        'width'  => 200,
                        'y'      => 200,
                        'label'  => 'two',
                        'x'      => 300,
                        'height' => 100
                    }
                ]
            },
            {
                'width'  => 100,
                'height' => 400,
                'items'  => [
                    {
                        'width'  => 100,
                        'y'      => 0,
                        'label'  => 'four',
                        'x'      => 0,
                        'height' => 200
                    },
                    {
                        'width'  => 100,
                        'y'      => 200,
                        'label'  => 'three',
                        'x'      => 0,
                        'height' => 200
                    }
                ]
            }
        ],
        'Properlly packed or not'
    );
};

done_testing;
