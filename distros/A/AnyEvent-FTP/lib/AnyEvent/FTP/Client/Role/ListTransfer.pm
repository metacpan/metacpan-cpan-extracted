package AnyEvent::FTP::Client::Role::ListTransfer;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Fetch transfer interface for AnyEvent::FTP objects
our $VERSION = '0.16'; # VERSION

sub xfer
{
  my($self, $fh, $local) = @_;

  my $handle = $self->handle($fh);

  $handle->on_read(sub {
    $handle->push_read(line => sub {
      my($handle, $line) = @_;
      $line =~ s/\015?\012//g;
      push @{ $local }, $line;
    });
  });
}

sub convert_local
{
  my($self, $local) = @_;
  return $local;
}

sub push_command
{
  my $self = shift;
  my $cv = $self->{client}->push_command(
    @_,
  );

  $cv->cb(sub {
    eval { $cv->recv };
    my $err = $@;
    $self->{cv}->croak($err) if $err;
  });

  $self->on_eof(sub {
    $cv->cb(sub {
      my $res = eval { $cv->recv };
      $self->{cv}->send($res) unless $@;
    });
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Role::ListTransfer - Fetch transfer interface for AnyEvent::FTP objects

=head1 VERSION

version 0.16

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
