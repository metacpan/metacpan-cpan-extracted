package AnyEvent::FTP::Server::Context::Memory;

use strict;
use warnings;
use 5.010;
use Moo;
use Path::Class::File;
use Path::Class::Dir;

extends 'AnyEvent::FTP::Server::Context';

# ABSTRACT: FTP Server client context class with full read/write access
our $VERSION = '0.18'; # VERSION


with 'AnyEvent::FTP::Server::Role::Auth';
with 'AnyEvent::FTP::Server::Role::Help';
with 'AnyEvent::FTP::Server::Role::Old';
with 'AnyEvent::FTP::Server::Role::Type';
with 'AnyEvent::FTP::Server::Role::TransferPrep';


sub store
{
  # The store for this class is global.
  # if you wanted each connection or user
  # to have their own store you could subclass
  # and redefine the store method as apropriate
  state $store = {};
  $store;
}


has cwd => (
  is      => 'rw',
  default => sub {
    Path::Class::Dir->new_foreign('Unix', '/');
  },
);


sub _first_index (&@)
{
  my $f = shift;
  foreach my $i ( 0 .. $#_ )
  {
    local *_ = \$_[$i];
    return $i if $f->();
  }
  return -1;
}

sub find
{
  my($self, $path) = @_;
  $path = Path::Class::Dir->new_foreign('Unix', $path) unless ref $path;
  $path = Path::Class::Dir->new_foreign('Unix', $self->cwd, $path)
    unless $path->is_absolute;

  my $store = $self->store;

  return $store if $path eq '/';

  my @list = $path->components;

  while(1)
  {
    my $i = _first_index { $_ eq '..' } @list;
    last if $i == -1;
    if($i > 1)
    {
      splice @list, $i-1, 2;
    }
    else
    {
      splice @list, $i, 1;
    }
  }

  shift @list; # shift off the root
  my $top = pop @list;

  foreach my $part (@list)
  {
    if(exists($store->{$part}) && ref($store->{$part}) eq 'HASH')
    {
      $store = $store->{$part};
    }
    else
    {
      return;
    }
  }

  if(exists $store->{$top})
  { return $store->{$top} }
  else
  { return }
}


sub rename_from
{
  my($self, $value) = @_;
  $self->{rename_from} = $value if defined $value;
  $self->{rename_from};
}


sub help_cwd { 'CWD <sp> pathname' }

sub cmd_cwd
{
  my($self, $con, $req) = @_;

  my $dir = Path::Class::Dir->new_foreign('Unix', $req->args)->cleanup;
  $dir = $dir->absolute($self->cwd) unless $dir->is_absolute;

  my @list = grep !/^\.$/, $dir->components;

  while(1)
  {
    my $i = _first_index { $_ eq '..' } @list;
    last if $i == -1;
    if($i > 1)
    {
      splice @list, $i-1, 2;
    }
    else
    {
      splice @list, $i, 1;
    }
  }


  $dir = Path::Class::Dir->new_foreign('Unix', @list);

  if(ref($self->find($dir)) eq 'HASH')
  {
    $self->cwd($dir);
    $con->send_response(250 => 'CWD command successful');
  }
  else
  {
    $con->send_response(550 => 'CWD error');
  }

  $self->done;
}


sub help_cdup { 'CDUP' }

sub cmd_cdup
{
  my($self, $con, $req) = @_;

  my $dir = $self->cwd->parent;

  if(ref($self->find($dir)) eq 'HASH')
  {
    $self->cwd($dir);
    $con->send_response(250 => 'CDUP command successful');
  }
  else
  {
    $con->send_response(550 => 'CDUP error');
  }

  $self->done;
}


sub help_pwd { 'PWD' }

sub cmd_pwd
{
  my($self, $con, $req) = @_;

  my $cwd = $self->cwd;
  $con->send_response(257 => "\"$cwd\" is the current directory");
  $self->done;
}


sub help_size { 'SIZE <sp> pathname' }

sub cmd_size
{
  my($self, $con, $req) = @_;

  my $file = $self->find(Path::Class::File->new_foreign('Unix', $req->args));

  if(defined($file) && !ref($file))
  {
    $con->send_response(213 => length $file);
  }
  elsif(defined $file)
  {
    $con->send_response(550 => $req->args . ": not a regular file");
  }
  else
  {
    $con->send_response(550 => $req->args . ": No such file or directory");
  }

  $self->done;
}


sub help_mkd { 'MKD <sp> pathname' }

sub cmd_mkd
{
  my($self, $con, $req) = @_;

  my $path = Path::Class::Dir->new_foreign('Unix', $req->args);
  my $file = $self->find($path->parent);
  if($path->basename ne '' && defined($file) && ref($file) eq 'HASH')
  {
    if(exists $file->{$path->basename})
    {
      $con->send_response(521 => "\"$path\" directory exists");
    }
    else
    {
      $file->{$path->basename} = {};
      $con->send_response(257 => "\"$path\" new directory created");
    }
  }
  else
  {
    $con->send_response(550 => "MKD error");
  }
  $self->done;
}


sub help_rmd { 'RMD <sp> pathname' }

sub cmd_rmd
{
  my($self, $con, $req) = @_;

  # TODO: be more picky about rmd and file or dele a directory
  my $path = Path::Class::Dir->new_foreign('Unix', $req->args);
  my $file = $self->find($path->parent);
  if(defined($file) && ref($file) eq 'HASH')
  {
    if(exists $file->{$path->basename})
    {
      delete $file->{$path->basename};
      $con->send_response(250 => "RMD command successful");
    }
    else
    {
      $con->send_response(550 => "$path: No such file or directory");
    }
  }
  else
  {
    $con->send_response(550 => "$path: No such file or directory");
  }
  $self->done;

}


sub help_dele { 'DELE <sp> pathname' }

sub cmd_dele
{
  my($self, $con, $req) = @_;

  my $path = Path::Class::File->new_foreign('Unix', $req->args);
  my $file = $self->find($path->parent);
  if(defined($file) && ref($file) eq 'HASH')
  {
    if(exists $file->{$path->basename})
    {
      delete $file->{$path->basename};
      $con->send_response(250 => "File removed");
    }
    else
    {
      $con->send_response(550 => "$path: No such file or directory");
    }
  }
  else
  {
    $con->send_response(550 => "$path: No such file or directory");
  }
  $self->done;
}


sub help_rnfr { 'RNFR <sp> pathname' }

sub cmd_rnfr
{
  my($self, $con, $req) = @_;

  my $path = Path::Class::File->new_foreign('Unix', $req->args);
  my $dir = $self->find($path->parent);
  if(ref($dir) eq 'HASH')
  {
    if(exists $dir->{$path->basename})
    {
      $self->rename_from([$dir,$path->basename]);
      $con->send_response(350 => 'File or directory exists, ready for destination name');
    }
    else
    {
      $con->send_response(550 => 'No such file or directory');
    }
  }
  else
  {
    $con->send_response(550 => 'No such file or directory');
  }

  $self->done;
}


sub help_rnto { 'RNTO <sp> pathname' }

sub cmd_rnto
{
  my($self, $con, $req) = @_;

  my $from = $self->rename_from;

  unless(defined $from)
  {
    $con->send_response(503 => 'Bad sequence of commands');
    $self->done;
    return;
  }

  my $path = Path::Class::File->new_foreign('Unix', $req->args);
  my $dir = $self->find($path->parent);

  if(ref($dir) eq 'HASH')
  {
    if(exists $dir->{$path->basename})
    {
      $con->send_response(550 => 'File already exists');
    }
    else
    {
      $dir->{$path->basename} = delete $from->[0]->{$from->[1]};
      $con->send_response(250 => 'Rename successful');
    }
  }
  else
  {
    $con->send_response(550 => 'Rename failed');
  }
  $self->done;
}


sub help_stat { 'STAT [<sp> pathname]' }

sub cmd_stat
{
  my($self, $con, $req) = @_;

  my $file = $self->find($req->args);

  if(defined $file)
  {
    if(ref($file) eq 'HASH')
    {
      $con->send_response(211 => "It's a directory");
    }
    else
    {
      $con->send_response(211 => "It's a file");
    }
  }
  else
  {
    $con->send_response(450 => 'No such file or directory');
  }
  $self->done;
}


sub help_nlst { 'NLST [<sp> (pathname)]' }

sub cmd_nlst
{
  my($self, $con, $req) = @_;

  my $dir = $req->args;

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    $con->send_response(150 => "Opening ASCII mode data connection for file list");
    my @list;
    if($dir)
    {
      my $h = $self->find($dir);
      if(ref($h) eq 'HASH')
      {
        $dir = Path::Class::Dir->new_foreign('Unix', $dir);
        @list = map { $dir->file($_) } sort keys %$h;
      }
      else
      {
        $dir = Path::Class::File->new_foreign('Unix', $dir);
        @list = "$dir";
      }
    }
    else
    {
      my $h = $self->find($self->cwd);
      die 'unable to find cwd' unless defined $h;
      @list = sort keys %$h;
    }
    $self->data->push_write(join '', map { $_ . "\015\012" } @list);
    $self->data->push_shutdown;
    $con->send_response(226 => 'Transfer complete');
  };
  if(my $error = $@)
  {
    warn $error;
    if(eval { $error->can('errno') })
    { $con->send_response(550 => $error->errno) }
    else
    { $con->send_response(550 => 'Internal error') }
  };
  $self->clear_data;
  $self->done;
}

1;


# TODO: cmd_retr
# TODO: cmd_list
# TODO: cmd_stor
# TODO: cmd_appe
# TODO: cmd_stou

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Context::Memory - FTP Server client context class with full read/write access

=head1 VERSION

version 0.18

=head1 SYNOPSIS

 use AnyEvent::FTP::Server;
 
 my $server = AnyEvent::FTP::Server->new(
   default_context => 'AnyEvent::FTP::Server::Context::Memory',
 );

=head1 DESCRIPTION

This class provides a context for L<AnyEvent::FTP::Server> which uses
memory to provide storage.  Once the server process terminates, all
data stored is lost.

Note that this implementation is incomplete.

=head1 ROLES

This class consumes these roles:

=over 4

=item *

L<AnyEvent::FTP::Server::Role::Auth>

=item *

L<AnyEvent::FTP::Server::Role::Help>

=item *

L<AnyEvent::FTP::Server::Role::Old>

=item *

L<AnyEvent::FTP::Server::Role::Type>

=back

=head1 ATTRIBUTES

=head2 store

Has containing the directory tree for the context.

=head2 cwd

The current working directory for the context.  This
will be an L<Path::Class::Dir>.

=head2 find

Returns the hash (for directory) or scalar (for file) of
a file in the filesystem.

=head2 rename_from

 my $filename = $context->rename_from;

The filename specified by the last FTP C<RNFR> command.

=head1 COMMANDS

In addition to the commands provided by the above roles,
this context provides these FTP commands:

=over 4

=item CWD

=item CDUP

=item PWD

=item SIZE

=item MKD

=item RMD

=item DELE

=item RNFR

=item RNTO

=item STAT

=item NLST

=back

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
