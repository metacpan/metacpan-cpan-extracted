use strict;
use warnings;
use Test::More;
use Audio::Chromaprint;

note "version = ", Audio::Chromaprint->get_version;

my $cp = Audio::Chromaprint->new;
isa_ok $cp, 'Audio::Chromaprint';

eval { $cp->start(44100, 1) };
is "$@", '', 'cp->start';

eval { $cp->finish };
is "$@", '', 'cp->finish';

undef $cp;
pass 'did not crash calling free';

done_testing;
