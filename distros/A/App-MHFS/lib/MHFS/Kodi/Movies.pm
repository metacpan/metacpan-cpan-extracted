package MHFS::Kodi::Movies v0.7.0;
use 5.014;
use strict; use warnings;
use File::Basename qw(basename);
use MHFS::Kodi::Util qw(html_list_item);
use MHFS::Kodi::Movie;

sub Format {
    my ($moovies) = @_;
    my @sortedkeys = sort {basename($a) cmp basename($b)} keys %$moovies;
    my @movies = map {
        my $movie = MHFS::Kodi::Movie::Format($moovies->{$_});
        $movie->{id} = $_;
        $movie
    } @sortedkeys;
    \@movies
}

sub TO_JSON {
    my ($self) = @_;
    {movies => Format($self->{movies})}
}

sub TO_HTML {
    my ($self) = @_;
    my $movies = Format($self->{movies});
    my $buf = '<style>ul{list-style: none;} li{margin: 10px 0;}</style><ul>';
    foreach my $movie (@$movies) {
        $buf .= html_list_item($movie->{id}, 1);
    }
    $buf .= '</ul>';
    $buf
}
1;
