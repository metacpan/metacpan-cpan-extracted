package MHFS::Kodi::TVShows v0.7.0;
use 5.014;
use strict; use warnings;
use File::Basename qw(basename);
use MHFS::Kodi::Util qw(html_list_item);
use MIME::Base64 qw(encode_base64url);
use MHFS::Kodi::SeasonLite;

sub Format {
    my ($tvvshows) = @_;
    my @sortedkeys = sort {basename($a) cmp basename($b)} keys %$tvvshows;
    my @tvshows = map {
        my %tvshow = %{$tvvshows->{$_}};
        my @sortedseasons = sort keys %{$tvshow{seasons}};
        my @seasons = map {
            my $season = $tvshow{seasons}{$_};
            MHFS::Kodi::SeasonLite::Format($season, $_)
        } @sortedseasons;
        $tvshow{seasons} = \@seasons;
        \%tvshow
    } @sortedkeys;
    \@tvshows
}

sub TO_JSON {
    my ($self) = @_;
    {tvshows => Format($self->{tvshows})}
}

sub TO_HTML {
    my ($self) = @_;
    my $tvshows = Format($self->{tvshows});
    my $buf = '<style>ul{list-style: none;} li{margin: 10px 0;}</style><ul>';
    foreach my $tvshow (@$tvshows) {
        $buf .= html_list_item($tvshow->{name}, 1);
    }
    $buf .= '</ul>';
    $buf
}
1;
