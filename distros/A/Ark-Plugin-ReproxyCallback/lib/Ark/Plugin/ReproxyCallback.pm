package Ark::Plugin::ReproxyCallback;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Ark::Plugin;

use URI;

sub reproxy {
    my $c = shift;
    my $args = @_ > 1 ? {@_} : $_[0];
    my $res  = $c->response;

    if (my $req = $args->{request}) {
        $res->header('X-Reproxy-Method' => $req->method);
        $res->header('X-Reproxy-URL'    => $req->uri);
        for my $h ($req->headers->header_field_names) {
            $res->header('X-Reproxy-Header-' . $h => $req->header($h));
        }
    }

    if (my $callback = $args->{callback}) {
        $res->header('X-Reproxy-Callback' => $callback);
    }

    $res->body('') unless $res->has_body;
}

after prepare_action => sub {
    my $c = shift;

    if (my $uri = $c->request->header('X-Reproxy-Original-URL')) {
        $c->request->header('X-Reproxy-Callback-URL' => $c->request->uri );
        $c->request->uri(URI->new($uri));
    }
};

1;
__END__

=encoding utf-8

=head1 NAME

Ark::Plugin::ReproxyCallback - Ark plugins for Reproxy

=head1 SYNOPSIS

    use Ark;
    use_plubins qw/
        ReproxyCallback
    /;

=head1 DESCRIPTION

Ark::Plugin::ReproxyCallback is Ark plugin for supporting Reproxy.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
