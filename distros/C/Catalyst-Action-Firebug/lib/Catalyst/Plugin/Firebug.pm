package Catalyst::Plugin::Firebug;
use strict;
use warnings;

use NEXT;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Plugin::Firebug - Catalyst plugin for Firebug Lite

=head1 SYNOPSIS

    use Catalyst qw/Firebug/;

=head1 DESCRIPTION

Catalyst plugin for Firebug Lite.

If you load this plugin, and your app running on debug mode or $ENV{FIREBUG_DEBUG} is set,
this plugin insert firebug lite tags to its output automaticaly.

=head1 CONFIGURATION

You can specify firebug.js path by following config:

    $c->config->{firebug}{path} = '/path/to/firebug.js';

Default path is '/js/firebug/firebug.js'.

=head1 SEE ALSO

Firebug, http://getfirebug.com/

Firebug Lite, http://getfirebug.com/lite.html

=head1 EXTENDED METHODS

=head2 finalize

=cut

sub finalize {
    my $c = shift;
    return $c->NEXT::finalize unless $c->debug || $ENV{FIREBUG_DEBUG};

    if ($c->res->content_type =~ /html/) {
        $c->log->debug('enable firebug lite');

        my $firebug = $c->uri_for( $c->config->{firebug}{path} || '/js/firebug/firebug.js' );

        my $body = $c->res->body;

        if ($body =~ m!<head.*?>.*?</head>!is) {
            $body =~ s!(<head.*?>(?:.*?))(</head>)!$1<script type="text/javascript" src="$firebug"></script>$2!is;
        }
        else {
            $body .= qq{<script type="text/javascript" src="$firebug"></script>};
        }

        if ($body =~ m!<html.*?>.*?</html>!is) {
            $body =~ s!(<html.*?)>!$1 debug="true">!is;
        }
        else {
            $body = qq{<html debug="true">$body</html>};
        }

        $c->res->body( $body );
    }

    $c->NEXT::finalize;
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
