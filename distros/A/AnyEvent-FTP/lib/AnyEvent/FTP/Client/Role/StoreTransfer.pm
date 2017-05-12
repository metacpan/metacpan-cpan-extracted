package AnyEvent::FTP::Client::Role::StoreTransfer;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Store transfer interface for AnyEvent::FTP objects
our $VERSION = '0.09'; # VERSION

sub xfer
{
  my($self, $fh, $local) = @_;
  
  my $handle = $self->handle($fh);
  
  return unless defined $local;
  
  $handle->on_drain(sub {
    my $data = $local->();
    if(defined $data)
    {
      $handle->push_write($data);
    }
    else
    {
      $handle->push_shutdown;
    }
  });
}

sub convert_local
{
  my($self, $local) = @_;
  
  return unless defined $local;
  return $local if ref($local) eq 'CODE';
  
  if(ref($local) eq '')
  {
    open my $fh, '<', $local;
    $self->on_close(sub { close $fh });
    return sub {
      local $/;
      <$fh>;
    };
  }
  elsif(ref($local) eq 'SCALAR')
  {
    my $buffer = $$local;
    return sub {
      my $tmp = $buffer;
      undef $buffer;
      $tmp;
    };
  }
  elsif(ref($local) eq 'GLOB')
  {
    sub {
      # TODO: for big files, maybe
      # break this up into batches
      local $/;
      <$local>;
    };
  }
  else
  {
    die 'bad local type';
  }
}

sub push_command
{
  my $self = shift;
  $self->{client}->push_command(
    @_,
    $self->cv,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Role::StoreTransfer - Store transfer interface for AnyEvent::FTP objects

=head1 VERSION

version 0.09

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
