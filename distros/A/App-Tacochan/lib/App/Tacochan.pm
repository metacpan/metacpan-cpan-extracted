package App::Tacochan;
use strict;
use warnings;
our $VERSION = '0.07';

1;
__END__

=head1 NAME

App::Tacochan - Skype message delivery by HTTP

=head1 SYNOPSIS

  tacochan

=head1 OPTIONS

=over 4

=item -o, --host

The interface a TCP based server daemon binds to. Defauts to undef,
which lets most server backends bind the any (*) interface. This
option doesn't mean anything if the server does not support TCP
socket.

=item -p, --port (default: 4969)

The port number a TCP based server daemon listens on. Defaults to
4969. This option doesn't mean anything if the server does not support
TCP socket.

=item -r, --reverse-proxy

treat X-Forwarded-For as REMOTE_ADDR if REMOTE_ADDR match this argument.

see L<Plack::Middleware::ReverseProxy>.

=item -h, --help

Show help for this command.

=item -v, --version

Show version.

=back

=head1 SEE ALSO

L<App::Ikachan>, L<Skype::Any>, L<Twiggy>

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym at gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
