#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use t::lib::Utils;
use t::app::Main;
use DateTime;
use Data::Dumper;

plan tests => 10;

my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({ add_drop_table => 1 });
populate_database($schema);

my @rs = $schema->resultset('Cd')->search({'title' => 'Bad'});
my $cd = $rs[0];
my $rh_result = {'artistid' => $cd->artistid(),'cdid' => $cd->cdid(),'title' => $cd->title, 'date' => undef, 'last_listen' => undef};
is_deeply( $cd->get_all_column_data, $rh_result, "column_data return all column value of object, title is not hided");

# test retro-compatibility
is_deeply( $cd->get_column_data, $cd->columns_data, "columns_data is deprecated but run");

my $artist = $cd->artist;
is_deeply($cd->artist_column_data,$artist->get_column_data, "artist_column_data return column data of artist");

# test retro-compatibility
is_deeply( $cd->artist_column_data, $cd->artist_columns_data, "artist_column_data is deprecated but run");

my @tracks = $cd->tracks_column_data;
is(scalar(@tracks), 3, "3 tracks for cd `Bad'");
my @track = $schema->resultset('Track')->search({title => $tracks[0]->{'title'}});

is_deeply($track[0]->get_column_data(), $tracks[0], "tracks_column data return tracks on column data form");
my $options;
$options->{columns} = [ 'cdid','trackid']; #test options->{columns}
my @track_keys;
foreach my $key (keys %{$track[0]->get_column_data($options)}){
  push @track_keys, $key;
}
is_deeply (\@track_keys, $options->{columns}, "tracks_column data return only the column we give" );

# test retro-compatibility
is_deeply(  [$cd->tracks_column_data],  [$cd->tracks_columns_data], "artist_column_data is deprecated but run");

# date and datetime format
my $date  = DateTime->now();
$cd->date($date);
$cd->last_listen($date);
my $format_date = $cd->date->ymd;
my $format_last_listen = $cd->last_listen->ymd.' '.$cd->last_listen->hms;
my $rh_result_date_with_title = {'artistid' => $cd->artistid(),'cdid' => $cd->cdid(),'title' => $cd->title, 'date' => $format_date, 'last_listen' => $format_last_listen};
is_deeply( $cd->get_all_column_data, $rh_result_date_with_title, "column_data return all column value of object with format date and title is not hided");

#use get_column_data with hide field
my $rh_result_date = {'artistid' => $cd->artistid(),'cdid' => $cd->cdid(), 'date' => $format_date, 'last_listen' => $format_last_listen};
is_deeply( $cd->get_column_data, $rh_result_date, "column_data return all column value of object with format date and title is hided");


