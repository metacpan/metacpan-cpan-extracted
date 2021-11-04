package AnyEvent::FTP::Client::Transfer::Active;

use strict;
use warnings;
use Moo;
use 5.010;
use AnyEvent;
use AnyEvent::Socket qw( tcp_server );

extends 'AnyEvent::FTP::Client::Transfer';

# ABSTRACT: Active transfer class for asynchronous ftp client
our $VERSION = '0.18'; # VERSION

sub BUILD
{
  my($self) = @_;

  my $local = $self->convert_local($self->local);

  my $count = 0;
  my $guard;
  $guard = tcp_server $self->client->{my_ip}, undef, sub {
    my($fh, $host, $port) = @_;
    # TODO double check the host/port combo here.

    return close $fh if ++$count > 1;

    undef $guard; # close to additional connections.

    $self->xfer($fh,$local);
  }, sub {

    my($fh, $host, $port) = @_;
    my $ip_and_port = join(',', split(/\./, $self->client->{my_ip}), $port >> 8, $port & 0xff);

    my $w;
    $w = AnyEvent->timer(after => 0, cb => sub {
      $self->push_command(
        [ PORT => $ip_and_port ],
        ($self->restart > 0 ? ([ REST => $self->restart ]) : ()),
        $self->command,
      );
      undef $w;
    });
  };

  $self->cv->cb(sub {
    my $res = eval { shift->recv } // $@;
    $self->emit('close' => $res);
  });

}

package AnyEvent::FTP::Client::Transfer::Active::Fetch;

use Moo;
extends 'AnyEvent::FTP::Client::Transfer::Active';

with 'AnyEvent::FTP::Client::Role::FetchTransfer';

package AnyEvent::FTP::Client::Transfer::Active::Store;

use Moo;
extends 'AnyEvent::FTP::Client::Transfer::Active';

with 'AnyEvent::FTP::Client::Role::StoreTransfer';

package AnyEvent::FTP::Client::Transfer::Active::List;

use Moo;
extends 'AnyEvent::FTP::Client::Transfer::Active';

with 'AnyEvent::FTP::Client::Role::ListTransfer';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Transfer::Active - Active transfer class for asynchronous ftp client

=head1 VERSION

version 0.18

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
