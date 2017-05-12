package Blikistan::MagicEngine::Perl;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use URI::Escape;

sub print_blog {
    my $self = shift;
    my $r = $self->{rester};
    
    my $params = $self->load_config;
    $params->{rester} = $r;
    $params->{blog_tag} ||= $self->{blog_tag};

    if (my $who = $self->{subblog}) {
        my $sub_tag = $params->{subblogs}{$who};
        $params->{blog_tag} = $sub_tag ? $sub_tag->{blog_tag} : $who;
    }

    my $show_latest = delete $params->{show_latest_posts}
        || $self->{show_latest_posts};

    my @posts = $r->get_taggedpages($params->{blog_tag});
    @posts = splice @posts, 0, $show_latest;

    $r->accept('text/html');
    $params->{posts} = [
        map { 
            title => $_, 
            content => _get_page($r, $_),
            permalink => _linkify($r, $_),
            date => scalar($r->response->header('Last-Modified')),
        }, @posts,
    ];

    return $self->render_template( $params );
}

sub _linkify {
    my $r = shift;
    my $page = uri_escape(shift);
    return $r->server . '/' . $r->workspace . "/index.cgi?$page";
}

sub _get_page {
    my $r = shift;
    my $page_name = shift;
    my $html = $r->get_page($page_name) || '';

    while ($html =~ s/<a href="([\w_]+)"\s*/'<a href="' . _linkify($r, $1) . '"'/eg) {}

    $html =~ s#^<div class="wiki">(.+)</div>\s*$#$1#s;
    return $html;
}

1;

