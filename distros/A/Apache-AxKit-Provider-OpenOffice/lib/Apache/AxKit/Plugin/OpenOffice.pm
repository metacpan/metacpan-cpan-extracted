# $Id: OpenOffice.pm,v 1.6 2003/01/31 11:52:33 matt Exp $

package Apache::AxKit::Plugin::OpenOffice;

use strict;
use Apache::Constants qw(OK);
use Apache::AxKit::Provider::OpenOffice;

use vars qw($VERSION);

$VERSION = '1.02';

sub handler {
    my $r = shift;

    if ($r->filename =~ /\.sxw$/i) {
        my $cgi = Apache::Request->instance($r);
        my $uri = $r->uri;
        $cgi->parms->set('oo.request.uri' => $uri );
        $uri =~ s(^.*/)();
        $cgi->parms->set('oo.sxwfile' => $uri );

#        my $path_info = $r->path_info;
#        $path_info =~ s|^/||;
#        if (my $file = $path_info) {
#            $r->dir_config->set("oo_file", $file);
#            $r->notes('axkit_cache_extra', $r->notes('axkit_cache_extra') . ";oo_file=$file");
#        }
#        $r->dir_config->set("AxContentProvider", "Apache::AxKit::Provider::OpenOffice");
    }
    return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::OpenOffice - Plugin module to accompany OpenOffice provider

=head1 SYNOPSIS

  AxAddPlugin +Apache::AxKit::Plugin::OpenOffice

=head1 DESCRIPTION

This simple plugin allows 
