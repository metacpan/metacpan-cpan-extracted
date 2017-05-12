#!perl
#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 9;
my $mpd = Audio::MPD->new;


#
# testing absolute volume.
my $oldvol = $mpd->status->volume; # saving volume.
$mpd->volume(10); # init to sthg that we know
$mpd->volume(42);
is( $mpd->status->volume, 42, 'setting volume' );

#
# testing positive relative volume.
$mpd->volume('+9');
is( $mpd->status->volume, 51, 'increasing volume' );

#
# testing negative relative volume.
$mpd->volume('-4');
is( $mpd->status->volume, 47, 'decreasing volume' );
$mpd->volume($oldvol);  # resoring volume.

#
# testing outputs.
my @outputs = $mpd->outputs;
is( scalar(@outputs), 1, 'list of outputs' );
my $o = shift @outputs;
isa_ok( $o, 'Audio::MPD::Common::Output', "outputs return AMC:Output objects" );
is( $o->id,   0,      "AMC:O object: id" );
is( $o->name, "null", "AMC:O object: name" );

#
# testing disable_output.
$mpd->playlist->add( 'title.ogg' );
$mpd->playlist->add( 'dir1/title-artist-album.ogg' );
$mpd->playlist->add( 'dir1/title-artist.ogg' );
$mpd->play;
$mpd->output_disable(0);
sleep(1);
SKIP: {
    # FIXME?
    my $error = $mpd->status->error;
    skip "detection method doesn't always work - depends on timing", 1
        unless defined $error;
    like( $error, qr/^problems|All audio outputs are disabled/, 'disabling output' );
}

#
# testing enable_output.
$mpd->output_enable(0);
sleep(1);
$mpd->play; $mpd->pause;
is( $mpd->status->error, undef, 'enabling output' );

