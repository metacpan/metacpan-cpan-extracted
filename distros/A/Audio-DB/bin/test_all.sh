#!/bin/sh
DSN=$1
ADAPTOR=$2

mkdir tmp/
echo "Generating album histogram..."
./album_distribution.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root --width 1000 --height 600 -start 1940 -end 2004 > tmp/albums.png
echo "Generating song histogram..."
./song_distribution.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root --width 1000 --height 600 -start 1940 -end 2004  > tmp/songs.png 
echo "Finding artists with multiple genres assigned..."
./artists_with_multiple_genres.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root > tmp/artists_multiple_genres.out
echo "Generating full album list..."
./generate_album_list.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root > tmp/album_list.out
echo "Generating library statistics..."
./library_statistics.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root  > tmp/library_stats.out
echo "Finding albums that fall below bitrate threshold..."
./albums_below_threshold.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root -threshold 192 > tmp/albums_below_threshold.out
echo "Generating genre report..."
./genre_statistics.pl --dsn ${DSN} --adaptor ${ADAPTOR} --user root --pass root > tmp/genre_stats.out
