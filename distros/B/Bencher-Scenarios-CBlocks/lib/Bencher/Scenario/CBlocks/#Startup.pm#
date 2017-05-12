package Bencher::Scenario::CBlocks::Startup;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of C::Blocks compared to plain perl',
    modules => {
    },
    participants => [
        {
            name => 'perl',
            perl_cmdline=>["-Mstrict", "-Mwarnings", "-e1"],
        },
        {
            name => 'load_cblocks',
            perl_cmdline=>["-Mstrict", "-Mwarnings", "-MC::Blocks", "-e1"]},
        {
            name => 'load_cblocks_perlapi_types',
            perl_cmdline=>["-Mstrict", "-Mwarnings", "-MC::Blocks", "-MC::Blocks::PerlAPI", "-MC::Blocks::Types=uint", "-e", 'my uint $foo=0; cblock { $foo=5; }'],
            description => <<'_',

This is "some idea for the minimal cost of really using C::Blocks".

_
        },
    ],
};

1;
# ABSTRACT:

=head1 SEE ALSO
