package MHFS::Kodi::Movie v0.7.0;
use 5.014;
use strict; use warnings;
use MHFS::Kodi::Util qw(html_list_item);
use MHFS::Kodi::MovieEditions;

sub Format {
    my ($moovie) = @_;
    my %movie = %{$moovie};
    $movie{editions} = MHFS::Kodi::MovieEditions::Format(\%movie);
    \%movie
}

sub TO_JSON {
    my ($self) = @_;
    {movie => Format($self->{movie})}
}

sub TO_HTML {
    my ($self) = @_;
    my $editions = Format($self->{movie})->{editions};
    my $buf = '<style>ul{list-style: none;} li{margin: 10px 0;}</style><ul>';
    foreach my $edition (@$editions) {
        $buf .= html_list_item($edition->{id}, 1, $edition->{name});
    }
    $buf .= '</ul>';
    $buf
}
1;
