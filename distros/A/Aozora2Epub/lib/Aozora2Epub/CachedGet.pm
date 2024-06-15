package Aozora2Epub::CachedGet;
use strict;
use warnings;
use utf8;
use Carp qw/croak/;
use HTTP::Tiny;
use Cache::FileCache;
use Encode qw/decode/;
use Path::Tiny;
use parent 'Exporter';

our @EXPORT = qw(http_get);

our $cache = Cache::FileCache->new({
    namespace          => 'aozora',
    default_expires_in => '30 days',
    cache_root         => $ENV{AOZORA2EPUB_CACHE} || path($ENV{HOME}, '.aozora-epub'),
    auto_purge_interval => '1 day',
});

sub http_get {
    my $url = shift;

    if ($url->isa('URI')) {
        $url = $url->as_string;
    }
    my $content = $cache->get($url);
    return $content if $content;
    my $r = HTTP::Tiny->new->get($url);
    croak "$url: $r->{status} $r->{reason}" unless $r->{success};
    $content = $r->{content};

    my $encoding = 'utf-8';
    my $content_type = $r->{headers}{'content-type'};
    unless ($content_type =~ m{text/}) {
        $cache->set($url, $content);
        return $content; # binary
    }
    if ($content_type =~ /charset=([^;]+)/) {
        $encoding = $1;
    } elsif ($content =~ m{<meta http-equiv="content-type" content="[^"]+;charset=(\w+)"}i) {
        $encoding = $1;
    }
    $content = Encode::decode($encoding, $content);
    $cache->set($url, $content);
    return $content;
}

1;

__END__
