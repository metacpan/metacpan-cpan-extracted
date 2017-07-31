package AnyEvent::FTP::Client::Transfer::Passive;

use strict;
use warnings;
use Moo;
use 5.010;
use AnyEvent::Socket qw( tcp_connect );

extends 'AnyEvent::FTP::Client::Transfer';

# ABSTRACT: Passive transfer class for asynchronous ftp client
our $VERSION = '0.14'; # VERSION

sub BUILD
{
  my($self) = @_;

  my $local = $self->convert_local($self->local);

  my $data_connection = sub {
    my $res = shift;
    return if $res->is_preliminary;
    my($ip, $port) = $res->get_address_and_port;
    if(defined $ip && defined $port)
    {
      tcp_connect $ip, $port, sub {
        my($fh) = @_;
        unless($fh)
        {
          return "unable to connect to data port: $!";
        }

        $self->xfer($fh,$local);
      };
      return;
    }
    else
    {
      $res;
    }
  };

  $self->push_command(
    [ 'PASV', undef, $data_connection ],
    ($self->restart > 0 ? ([ REST => $self->restart ]) : ()),
    $self->command,
  );

  $self->cv->cb(sub {
    my $res = eval { shift->recv } // $@;
    $self->emit('close' => $res);
  });
}

package AnyEvent::FTP::Client::Transfer::Passive::Fetch;

use Moo;
extends 'AnyEvent::FTP::Client::Transfer::Passive';

with 'AnyEvent::FTP::Client::Role::FetchTransfer';

package AnyEvent::FTP::Client::Transfer::Passive::Store;

use Moo;
extends 'AnyEvent::FTP::Client::Transfer::Passive';

with 'AnyEvent::FTP::Client::Role::StoreTransfer';

package AnyEvent::FTP::Client::Transfer::Passive::List;

use Moo;
extends 'AnyEvent::FTP::Client::Transfer::Passive';

with 'AnyEvent::FTP::Client::Role::ListTransfer';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Transfer::Passive - Passive transfer class for asynchronous ftp client

=head1 VERSION

version 0.14

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
