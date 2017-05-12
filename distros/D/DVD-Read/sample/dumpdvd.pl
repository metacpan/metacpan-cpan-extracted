#!/bin/env perl

use strict;
use warnings;
use DVD::Read;

my @dvds = @ARGV;

foreach my $location (@dvds) {
    my $dvd = DVD::Read->new($location) or do {
        warn "Cant read $location\n";
        next;
    };

    print ($dvd->volid || '');
    printf(" %d titles\n",
        $dvd->titles_count);

    foreach my $titleno (1 .. $dvd->titles_count) {
        my $title = $dvd->get_title($titleno);
        printf("  * Title: %02d (%2d) %2d ch. %2d ang. %8dms\n",
            $titleno, $title->title_nr, $title->chapters_count,
            $dvd->title_angles_count($titleno), $title->length,
        );
        foreach my $audio ($title->audios) {
            printf("    * Audio     %02d (%s) (%s)\n",
                $audio,
                $title->audio_language($audio) || '--',
                $title->audio_format_txt($audio) || 'N/A',
            );
        }
        foreach my $subtitle ($title->subtitles) {
            printf("    * Subtitle  %02d (%s)\n",
                $subtitle, $title->subtitle_language($subtitle),
            );
        }
        foreach my $ch (1 .. $title->chapters_count) {
            printf("    * Chapitre  %02d %8dms (%d => %d)\n",
                $ch,
                $title->chapter_offset($ch),
                $title->chapter_first_sector($ch),
                $title->chapter_last_sector($ch),
            );
        }
    }
}
