package MHFS::Kodi::Util v0.7.0;
use 5.014;
use strict; use warnings;
use Exporter 'import';
use MHFS::Util qw(uri_escape_path_utf8 escape_html_noquote);
our @EXPORT_OK = qw(html_list_item);

sub html_list_item {
    my ($item, $isdir, $label) = @_;
    $label //= $item;
    my $url = uri_escape_path_utf8($item);
    $url .= '/?fmt=html' if($isdir);
    '<li><a href="' . $url .'">'. ${escape_html_noquote($label)} .'</a></li>'
}
1;
