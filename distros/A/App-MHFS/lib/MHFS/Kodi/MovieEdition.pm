package MHFS::Kodi::MovieEdition v0.7.0;
use 5.014;
use strict; use warnings;
use File::Basename qw(basename);
use MHFS::Kodi::Util qw(html_list_item);
use MHFS::Kodi::MoviePart;
use MHFS::Util qw(str_to_base64url);

sub Format {
    my ($sourcename, $editionname, $ediition) = @_;
    my @sortedkeys = sort {basename($a) cmp basename($b)} keys %$ediition;
    my @parts = map {
        MHFS::Kodi::MoviePart::Format($editionname, $_, $ediition->{$_})
    } @sortedkeys;
    my $editionid = "$sourcename/".str_to_base64url($editionname);
    my %edition = ( id => $editionid, name => basename($editionname), parts => \@parts);
    \%edition
}

sub TO_JSON {
    my ($self) = @_;
    {edition => Format($self->{source}, $self->{editionname}, $self->{edition})}
}

sub TO_HTML {
    my ($self) = @_;
    my $parts = $self->TO_JSON()->{edition}{parts};
    my $buf = '<style>ul{list-style: none;} li{margin: 10px 0;}</style><ul>';
    foreach my $part (@$parts) {
        $buf .= html_list_item($part->{id}, 1, $part->{name});
    }
    $buf .= '</ul>';
    $buf
}
1;
