package MHFS::Kodi::MoviePart v0.7.0;
use 5.014;
use strict; use warnings;
use File::Basename qw(basename);
use MHFS::Kodi::Util qw(html_list_item);
use MHFS::Util qw(str_to_base64url);

sub _format_movie_subs {
    my ($subs) = @_;
    my @subs = map {
        # kodi needs a basename with a parsable extension
        my ($loc, $filename) = $_ =~ /^(.+\/|)([^\/]+)$/;
        $loc = str_to_base64url($loc);
        "$loc-sb/$filename"
    } keys %$subs;
    \@subs
}

sub Format {
    my ($editionname, $name, $paart) = @_;
    my $b64_name = str_to_base64url($name);
    my %part = (
        id => "$b64_name-pt",
        name => basename("$editionname$name")
    );
    if (exists $paart->{subs}) {
        $part{subs} = _format_movie_subs($paart->{subs});
    }
    \%part
}

sub TO_JSON {
    my ($self) = @_;
    {part => Format($self->{editionname}, $self->{partname}, $self->{part})}
}

sub TO_HTML {
    my ($self) = @_;
    my $part = $self->TO_JSON()->{part};
    my $buf = '<style>ul{list-style: none;} li{margin: 10px 0;}</style><ul>';
    $buf .= html_list_item("../".$part->{id}, 0, $part->{name});
    if (exists $part->{subs}) {
        foreach my $sub (@{$part->{subs}}) {
            $buf .= html_list_item($sub, 0, basename($sub));
        }
    }
    $buf .= '</ul>';
    $buf
}
1;
