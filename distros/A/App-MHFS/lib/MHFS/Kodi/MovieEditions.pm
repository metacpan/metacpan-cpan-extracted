package MHFS::Kodi::MovieEditions v0.7.0;
use 5.014;
use strict; use warnings;
use File::Basename qw(basename);
use MHFS::Kodi::Util qw(html_list_item);
use MHFS::Kodi::MovieEdition;

# transform $diritems{movie}{editions}{source/name}{|parts}
# to        $diritems{movie}{editions}[{name, parts}]
sub Format {
    my ($self) = @_;
    my $ediitions = $self->{editions};
    my @sortedkeys = sort {basename($a) cmp basename($b)} keys %$ediitions;
    my @editions = map {
        my ($sourcename, $editionname) = split('/', $_, 2);
        MHFS::Kodi::MovieEdition::Format($sourcename, $editionname, $ediitions->{$_})
    } @sortedkeys;
    \@editions
}

sub TO_JSON {
    my ($self) = @_;
    {editions => Format($self)}
}

sub TO_HTML {
    my ($self) = @_;
    my $editions = Format($self);
    my $buf = '<style>ul{list-style: none;} li{margin: 10px 0;}</style><ul>';
    foreach my $edition (@$editions) {
        $buf .= html_list_item("../".$edition->{id}, 1, $edition->{name});
    }
    $buf .= '</ul>';
    $buf
}
1;
