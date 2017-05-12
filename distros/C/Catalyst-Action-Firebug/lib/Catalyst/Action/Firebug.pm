package Catalyst::Action::Firebug;
use strict;
use warnings;

use base qw/Catalyst::Action/;
use NEXT;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Action::Firebug - Catalyst action for embedding Firebug Lite tag

=head1 SYNOPSIS

    sub end : ActionClass('Firebug') {
        my ($self, $c) = @_;
        $c->forward( $c->view('TT') );
    }
    
    # or combination with Action::RenderView
    sub render : ActionClass('RenderView') {}
    
    sub end : ActionClass('Firebug') {
        my ($self, $c) = @_;
        $c->forward('render');
    }

=head1 DESCRIPTION

Catalyst action for Firebug Lite.

If your app running on debug mode or $ENV{FIREBUG_DEBUG} is set,
this action insert firebug lite tags to its output automaticaly.

=head1 CONFIGURATION

    $c->config->{firebug}{path} = '/path/to/firebug.js';

=head2 KEYS

=over 4

=item path

URL path of firebug.js.  The default value is '/js/firebug/firebug.js'.

=item expand_panel

If it's true value, firebug panel is opened when page loading.

And you can use FIREBUG_EXPAND env instead of this key.

=back

=head1 SEE ALSO

Firebug, http://getfirebug.com/

Firebug Lite, http://getfirebug.com/lite.html

=head1 EXTENDED METHODS

=head2 execute

=cut

sub execute {
    my $self = shift;
    my ($controller, $c) = @_;
    my $res = $self->NEXT::execute(@_);
    return $res unless $c->debug || $ENV{FIREBUG_DEBUG};

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

        if ($c->config->{firebug}{expand_panel} || $ENV{FIREBUG_EXPAND}) {
            if ($body =~ m!<html.*?>.*?</html>!is) {
                $body =~ s!(<html.*?)>!$1 debug="true">!is;
            }
            else {
                $body = qq{<html debug="true">$body</html>};
            }
        }

        $c->res->body( $body );
    }

    $res;
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
