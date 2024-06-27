package Aozora2Epub::CachedGet;
use strict;
use warnings;
use utf8;
use Carp qw/croak/;
use HTTP::Tiny;
use Cache::FileCache;
use Encode qw/decode/;
use Path::Tiny;
use File::HomeDir;
use parent 'Exporter';

our @EXPORT = qw(http_get);

our $VERSION = '0.04';

our $CACHE;
init_cache();

sub init_cache {
    my $cache_dir = $ENV{AOZORA2EPUB_CACHE};
    unless ($cache_dir) {
        my $home = File::HomeDir->my_home;
        $home or die "Can't determin home directory. Please set an environment variable AOZORA2EPUB_CACHE\n";
        $cache_dir = path($home, '.aozora-epub');
    }

    $CACHE = Cache::FileCache->new({
        namespace          => 'aozora',
        default_expires_in => '30 days',
        cache_root         => $cache_dir,
        directory_umask => 077,
        auto_purge_interval => '1 day',
    });
}

sub http_get {
    my $url = shift;

    if ($url->isa('URI')) {
        $url = $url->as_string;
    }
    my $content = $CACHE->get($url);
    return $content if $content;
    my $r = HTTP::Tiny->new->get($url);
    croak "$url: $r->{status} $r->{reason}" unless $r->{success};
    $content = $r->{content};

    my $encoding = 'utf-8';
    my $content_type = $r->{headers}{'content-type'};
    unless ($content_type =~ m{text/}) {
        $CACHE->set($url, $content);
        return $content; # binary
    }
    if ($content_type =~ /charset=([^;]+)/) {
        $encoding = $1;
    } elsif ($content =~ m{<meta http-equiv="content-type" content="[^"]+;charset=(\w+)"}i) {
        $encoding = $1;
    }
    $content = Encode::decode($encoding, $content);
    $CACHE->set($url, $content);
    return $content;
}

1;

__END__
