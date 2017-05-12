package CogWiki;
use Mo;
extends 'Cog::App';

our $VERSION = '0.04';

use constant webapp_class => 'CogWiki::WebApp';
use constant maker_class => 'CogWiki::Maker';

package CogWiki::WebApp;
use Mo;
extends 'Cog::WebApp';

use constant SHARE_DIST => 'CogWiki';
use constant url_map => [
    '()',
    ['/' => 'redirect', ('/pages/')],
    ['/home/?' => 'home_page'],
    ['/pages/?' => 'page_list'],
    ['/page/([A-Z0-9]{4})/?' => 'page_display', ('$1')],
    ['/page/name/([^/]+)/?' => 'page_by_name', ('$1')],
    ['/tags/' => 'tag_list' ],
    ['/tag/([^/]+)/?' => 'tag_page_list', ('$1')],
];

use constant site_navigation => [
    '()',
    ['Home' => '/home/'],
    ['Recent Changes' => '/pages/'],
    ['Tags' => '/tags/'],
];

package CogWiki::Maker;
use Mo;
extends 'Cog::Maker';
use IO::All;

sub all_files {
    my $self = shift;
    return grep {
        $_->filename =~ /\.cog$/;
    } io($self->config->content_root)->all_files;
}

sub make_cache {
    my $self = shift;
    io('cache')->mkdir;

    my $time = time;
    my $page_list = [];
    my $blobs = {};

    $self->config->store->delete_tag_index; # XXX Temporary solution until can do smarter
    for my $page_file ($self->all_files) {
        my $page = $self->config->classes->{page}->from_text($page_file->all);
        my $id = $page->Short or next;

        for my $Name (@{$page->Name}) {
            my $name = $self->config->store->index_name($Name, $id);
            io->file("cache/name/$name.txt")->assert->print($id);
        }

        $self->config->store->index_tag($_, $id)
            for $self->all_tags($page);

        my $blob = {
            %$page,
            Id => $id,
            Type => $page->Type,
            Title => $page->Title,
            Time => $page->Time,
            size => length($page->Content),
            duration => $page->duration,
        };
        delete $blob->{Content};
        delete $blob->{Name};
        push @$page_list, $blob;
        $blobs->{$id} = $blob;

        $self->make_page_html($page, $page_file);

        delete $page->{content};
        io("cache/$id.json")->print($self->json->encode($blob));
    }
    io("cache/page-list.json")->print($self->json->encode($page_list));
    $self->make_tag_cloud($blobs);
}

sub make_page_html {
    my $self = shift;
    my $page = shift;
    my $page_file = shift;
    my $id = $page->Short;
    my $html_filename = "cache/$id.html";

    return if -e $html_filename and -M $html_filename < -M $page_file->name;

    my $markup = $page->markup || 'simple';
    my $method = "${markup}_to_html";
    my $html = $self->$method($page->Content);

    print $page_file->filename . " -> $html_filename\n";
    io($html_filename)->assert->print($html);
}

sub html_to_html {
    return $_[1];
}

sub txt_to_html {
    my $self = shift;
    my $html = shift;

    $html =~ s/&/&amp;/g;
    $html =~ s/</&lt;/g;
    $html =~ s/>/&gt;/g;

    $html = "<pre>$html</pre>\n";

    return $html;
}

sub pod_to_html {
    my $self = shift;
    my $pod = shift;

    my $html;
    my $p = Pod::Simple::HTML->new;
    $p->output_string(\$html);
    $p->parse_string_document($pod);

    $html =~ s/.*!-- start doc -->(.*?)<!-- end doc --.*/$1/s or die;

    return $html;
}

sub asc_to_html {
    my $self = shift;
    my $asciidoc = shift;

    my ($in, $out, $err) = ($asciidoc, '', '');
    my @cmd = qw(asciidoc -s -);
    IPC::Run::run(\@cmd, \$in, \$out, \$err, IPC::Run::timeout(30));

    return $out;
}

sub simple_to_html {
    my $self = shift;
    my $text = shift;
    return join '', map {
        chomp;
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s!(^|\n)( +)!$1 . '&nbsp;' x length($2)!ge;
        s!\n!<br />\n!g;
        "<p>$_</p>\n\n";
    } split /\n\n+/, $text;
}

1;
