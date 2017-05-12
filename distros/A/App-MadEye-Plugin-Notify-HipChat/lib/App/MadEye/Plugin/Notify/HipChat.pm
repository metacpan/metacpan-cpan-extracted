package App::MadEye::Plugin::Notify::HipChat;
use 5.008005;
use strict;
use warnings;
use utf8;
use base qw/App::MadEye::Plugin::Base/;

our $VERSION = "0.02";

use Furl;

sub notify : Hook {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->{config}->{config};
    my $url = $conf->{url} // "https://api.hipchat.com/v1/rooms/message";
    $url =~ s!/$!!g;

    my $auth_token     = $conf->{auth_token}     or die "missing auth_token";
    my $room_id        = $conf->{room_id}        or die "missing room_id";
    my $from           = $conf->{from}           // "ikachan";
    my $notify         = $conf->{notify}         // 0;
    my $msg            = $conf->{message}        // "";
    my $message_format = $conf->{message_format} // "html";
    my $color          = $conf->{color}          // "yellow";
    my $format         = $conf->{format}         // "json";

    while ( my ( $plugin, $results ) = each %$args ) {
        $plugin =~ s/.+::Agent:://;
        for my $result (@$results) {
            $msg .= "$plugin: ($result->{target}): $result->{message} ";

            my $ua = Furl->new(
                timeout => 5,
                agent   => "MadEye/$App::MadEye::VERSION"
            );
            my $res = $ua->post(
                $url,
                [],
                [
                    auth_token     => $auth_token,
                    room_id        => $room_id,
                    from           => $from,
                    message        => $msg,
                    message_format => $message_format,
                    notify         => $notify,
                    color          => $color,
                    format         => $format,
                ]
            );
            $res->is_success or die $res->status_line;
            $context->log( info => "posted to $room_id." );
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::MadEye::Plugin::Notify::HipChat - send message to HipChat

=head1 SCHEMA

    type: map
    mapping:
        url:
            type: str
            required: no (defalut: https://api.hipchat.com/v1/rooms/message)
        auth_token:
            type: str
            required: yes
        room_id:
            type: str
            required: yes
        message:
            type: str
            required: no
        from:
            type: str
            required: no (defalut: ikachan)
        message_format:
            type: str
            required: no (defalut: html)
        notify:
            type: int
            required: no (defalut: 0)
        color:
            type: str
            required: no (defalut: yellow)
        format:
            type: str
            required: no (defalut: json)

=head1 SEE ALSO

L<App::MadEye>, L<HipChat API|https://www.hipchat.com/docs/api/method/rooms/message>

=head1 LICENSE

Copyright (C) Kazuhiro Homma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazuhiro Homma E<lt>kazu.homma@gmail.comE<gt>

=cut

