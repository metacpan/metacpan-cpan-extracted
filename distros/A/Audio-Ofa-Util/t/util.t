#!perl
use strict;
use warnings;
use Test::More;
use Audio::Ofa::Util;
use Data::Dumper;

unless (-e 'do_web_tests') {
    plan skip_all => 'The Web Service tests must be manually enabled';
}

plan tests => 1;

my $util = Audio::Ofa::Util->new(
    fingerprint => 'AQzQMcIsDTBvKl0d8h7WHDMZ2h/hEJEP7xSrEUESqQoRCagG6A4iB7IRXBMiDbMIUwdhB4gFzgc7BLMDeQLGA0AC4QMRAooC1AOJApIBugFb6Ve+wdWe/E0gOOboCZD4JwHRR/YA/v/VFM4PaRXJDK0CCgIdFDT98weqGUoQ4QRfAbAGOgJVAisAtgJOAdEBZwC9AUMBNQCn/3IAjwD1AK0Ipink6BctwbOB79jlawL+6xow4PLC9GruQff5CPgNW/XQAbIZpQRe+UcPdg30/pH90gJuAOIB/f4wAJQAggCuABAAfQDTAGQAGv/3ADD/yPrW9FrTZGDkHfrfEAUc/g4BC9Y6+qr7lwkA91D2WvcvAOr8ZPEtAVn+fe7K80P+tgFE/x//LQB1/6D+xP9q/73///8i/vT/vQBZ/3v/M/+rCewO0yFIAUBBTOZQqcnzu/YAFs3vBe3t5dT3pQPz/W72w/wg//0BJ/GT9/D/8vzI+9X8R/6b/X/9av81/7P/dv+qAEAAG/99/rkA2ACU/7X+4tpuU/EPDeKns6cYzgq8APz9LPQcAUoE0gK+/Bv/Vvt2/5wCOf+j/uwBBwaNAJ4AJwG5/4//uv/uANgAawAzAFr/5QAxABMAsv80/4P/wAnZNj/c8NbdBeC4afpNEZk0wu56/kz9PiJRB4YAZgYaCWcGYAwj/sUNBwkG/5j94wBI/wf9s//R//4AkgAJ/yYAJwCE/7L+y/6VAIv/lf+LLxU9LQ==',
    duration => 216990,
);

my @ret = $util->musicdns_lookup() or die $util->error;

diag(Dumper \@ret);

SKIP: {
    @ret = $util->musicbrainz_lookup;

    unless (@ret) {
        if ($util->error =~ /Service Temporarily Unavailable/) {
            diag $util->error;
            skip $util->error, 1;
        }
        die $util->error;
    }

    ok (scalar(grep $_->title() eq 'Good Vibrations', @ret), "Right title (Looking for Good Vibrations in @{[map $_->title, @ret]})");
}

# Just check that these don't die:
# MusicBrainz does not have this PUID (as of today)
Audio::Ofa::Util->new(puids => ['27716ccf-7e2c-7860-8ac7-d0e2e6bbd075'])->musicbrainz_lookup();
# They'll probably never have this one:
Audio::Ofa::Util->new(puids => ['ffffffff-ffff-ffff-ffff-ffffffffffff'])->musicbrainz_lookup();
