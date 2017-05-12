package Blikistan::MagicEngine::TT2;
use strict;
use warnings;
use base 'Blikistan::MagicEngine';
use Template;
use FindBin;
use URI::Escape;
use JSON;

sub render_template {
    my $self = shift;
    my $params = $self->{params} = shift || {};
    my $r = $self->{rester};

    $self->load_rester_utils;

    $params->{magic_engine} = ref($self);
    my $output = '';
    my $tmpl = $self->{template_name};
    if ($self->{template_page}) {
        $r->accept('text/x.socialtext-wiki');
        my $content = $r->get_page($self->{template_page});
        if ($r->response->code eq '404') {
            $content = $self->default_content;
        }
        $content =~ s/^\.pre\n(.+?)\.pre\n?.*/$1/s;
        $tmpl = \$content;
    }

    # Hide password, so it's not visible to the templates
    $r->{password} = undef;

    my $path = join ': ', 
               grep { defined }
               ($self->{template_path}, $FindBin::Bin);
    my $template = Template->new( { INCLUDE_PATH => $path } );
    $template->process( $tmpl, $params, \$output) or
        die $template->error;
    return $output;
}

sub default_content {
    my $self = shift;
    return <<EOT;
<html>
<head><title>Blikistan Problem</title></head>
<body>
Could not find template at $self->{template_page}

[% IF yaml_error %]
<strong>[% yaml_error %]</strong>
[% END %]
</body>
</html>
EOT
}

sub load_rester_utils {
    my $self = shift;
    my $r = $self->{rester};

    my $show_latest = delete $self->{params}{show_latest_posts}
        || $self->{show_latest_posts};

    $self->{params}{tagged_pages} ||= sub {
        my $tag = shift;
        $r->accept('text/plain');
        my @posts = $r->get_taggedpages($tag);
        @posts = splice @posts, 0, $show_latest;

        $r->accept('text/html');
        return [ map { $self->_load_page($_) } @posts ];
    };

    $self->{params}{show_page} ||= sub {
        my $p = $self->_load_page(shift);
        return $p->{html};
    };

    $self->{params}{workspace_tags} ||= sub {
        my $skip = shift || '';
        $r->accept('application/json');
        my $tags = jsonToObj($r->get_workspace_tags);
        $tags = [ 
            sort { $b->{page_count} <=> $a->{page_count} } 
                grep { $_->{name} ne $skip }
                    @$tags 
        ];
        return $tags;
    };

    $self->{params}{abbrev_page} ||= sub {
        my $page   = shift;
        my $length = shift || 30;
        my $p = $self->_load_page($page);
        my $small = substr($p->{wikitext}, 0, $length);
        $small .= " ..." if $small ne $p->{wikitext};
        return $small;
    }
}

sub linkify {
    my $self = shift;

    my $p = $self->_load_page(shift);
    return $p->{page_uri};
}

sub _load_page {
    my $self = shift;
    my $page = uri_escape(shift);
    return $self->{_page}{$page} if $self->{_page}{$page};

    my $r    = $self->{rester};
    $r->accept('application/json');
    $r->json_verbose(1);
    my $p = $self->{_page}{$page} = jsonToObj( $r->get_page($page) );
    while ($p->{html} =~ s/<a href="([\w_]+)"\s*/'<a href="' . $self->linkify($1) . '"'/eg) {}

    $p->{html} =~ s#^<div class="wiki">(.+)</div>\s*$#$1#s;
    return $p;
}

1;
