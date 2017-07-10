package AnyEvent::FTP::Server::Context::FSRW;

use strict;
use warnings;
use 5.010;
use Moo;
use File::chdir;
use File::Share qw( dist_file );
use File::Which qw( which );
use File::Temp qw( tempfile );

extends 'AnyEvent::FTP::Server::Context::FS';

# ABSTRACT: FTP Server client context class with full read/write access
our $VERSION = '0.10'; # VERSION


with 'AnyEvent::FTP::Server::Role::TransferPrep';


sub _layer
{
  $_[0]->type eq 'A' ? $_[0]->ascii_layer : ':raw';
}

sub help_retr { 'RETR <sp> pathname' }

sub cmd_retr
{
  my($self, $con, $req) = @_;

  my $fn = $req->args;

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    use autodie;
    local $CWD = $self->cwd;

    if(-f $fn)
    {
      # TODO: re-write so that this does not blocks
      my $type = $self->type eq 'A' ? 'ASCII' : 'Binary';
      my $size = -s $fn;
      $con->send_response(150 => "Opening $type mode data connection for $fn ($size bytes)");
      open my $fh, '<', $fn;
      binmode $fh, $self->_layer;
      seek $fh, $self->restart_offset, 0 if $self->restart_offset;
      $self->data->push_write(do { local $/; <$fh> });
      close $fh;
      $self->data->push_shutdown;
      $con->send_response(226 => 'Transfer complete');
    }
    elsif(-e $fn && !-d $fn)
    {
      $con->send_response(550 => 'Permission denied');
    }
    else
    {
      $con->send_response(550 => 'No such file');
    }
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


sub help_nlst { 'NLST [<sp> (pathname)]' }

sub cmd_nlst
{
  my($self, $con, $req) = @_;

  my $dir = $req->args || '.';

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    use autodie;
    local $CWD = $self->cwd;

    $con->send_response(150 => "Opening ASCII mode data connection for file list");
    my $dh;
    opendir $dh, $dir;
    my @list =
      map { $req->args ? join('/', $dir, $_) : $_ }
      sort
      grep !/^\.\.?$/,
      readdir $dh;
    closedir $dh;
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


sub help_list { 'LIST [<sp> pathname]' }

sub cmd_list
{
  my($self, $con, $req) = @_;

  my $dir = $req->args || '.';
  $dir = '.' if $dir eq '-l';

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    use autodie;

    my @cmd = _shared_cmd('ls', '-l', $dir);
    my $cmd = join ' ', @cmd;

    local $CWD = $self->cwd;

    $con->send_response(150 => "Opening ASCII mode data connection for file list");
    my $dh;
    opendir $dh, $dir;
    $self->data->push_write(join "\015\012", split /\n/, `$cmd`);
    closedir $dh;
    $self->data->push_write("\015\012");
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


sub help_stor { 'STOR <sp> pathname' }

sub cmd_stor
{
  my($self, $con, $req) = @_;

  my $fn = $req->args;

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    use autodie;
    local $CWD = $self->cwd;

    my $type = $self->type eq 'A' ? 'ASCII' : 'Binary';
    $con->send_response(150 => "Opening $type mode data connection for $fn");

    open my $fh, '>', $fn;
    binmode $fh, $self->_layer;
    $self->data->on_read(sub {
      $self->data->push_read(sub {
        print $fh $_[0]{rbuf};
        $_[0]{rbuf} = '';
      });
    });
    $self->data->on_error(sub {
      close $fh;
      $self->data->push_shutdown;
      $con->send_response(226 => 'Transfer complete');
      $self->clear_data;
      $self->done;
    });
  };
  if(my $error = $@)
  {
    warn $error;
    if(eval { $error->can('errno') })
    { $con->send_response(550 => $error->errno) }
    else
    { $con->send_response(550 => 'Internal error') }
    $self->clear_data;
    $self->done;
  };
}


sub help_appe { 'APPE <sp> pathname' }

sub cmd_appe
{
  my($self, $con, $req) = @_;

  my $fn = $req->args;

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    use autodie;
    local $CWD = $self->cwd;

    my $type = $self->type eq 'A' ? 'ASCII' : 'Binary';
    $con->send_response(150 => "Opening $type mode data connection for $fn");

    open my $fh, '>>', $fn;
    binmode $fh, $self->_layer;
    $self->data->on_read(sub {
      $self->data->push_read(sub {
        print $fh $_[0]{rbuf};
        $_[0]{rbuf} = '';
      });
    });
    $self->data->on_error(sub {
      close $fh;
      $self->data->push_shutdown;
      $con->send_response(226 => 'Transfer complete');
      $self->clear_data;
      $self->done;
    });
  };
  if(my $error = $@)
  {
    warn $error;
    if(eval { $error->can('errno') })
    { $con->send_response(550 => $error->errno) }
    else
    { $con->send_response(550 => 'Internal error') }
    $self->clear_data;
    $self->done;
  };
}


sub help_stou { 'STOU (store unique filename)' }

sub cmd_stou
{
  my($self, $con, $req) = @_;

  my $fn = $req->args;

  unless(defined $self->data)
  {
    $con->send_response(425 => 'Unable to build data connection');
    return;
  }

  eval {
    use autodie;
    local $CWD = $self->cwd;

    my $fh;

    if($fn && ! -e $fn)
    {
      open $fh, '>', $fn;
    }
    else
    {
      ($fh,$fn) = tempfile( "aefXXXXXX", TMPDIR => 0 )
    }

    my $type = $self->type eq 'A' ? 'ASCII' : 'Binary';
    $con->send_response(150 => "FILE: $fn");

    binmode $fh, $self->_layer;
    $self->data->on_read(sub {
      $self->data->push_read(sub {
        print $fh $_[0]{rbuf};
        $_[0]{rbuf} = '';
      });
    });
    $self->data->on_error(sub {
      close $fh;
      $self->data->push_shutdown;
      $con->send_response(226 => 'Transfer complete');
      $self->clear_data;
      $self->done;
    });
  };
  if(my $error = $@)
  {
    warn $error;
    if(eval { $error->can('errno') })
    { $con->send_response(550 => $error->errno) }
    else
    { $con->send_response(550 => 'Internal error') }
    $self->clear_data;
    $self->done;
  };
}

{
  state $always_use_bundled_cmd = $ENV{ANYEVENT_FTP_BUNDLED_CMD};
  my %shared;
  sub _shared_cmd
  {
    my ($cmd, @args) = @_;

    unless (defined $shared{$cmd}) {
      my $which = which $cmd;
      if ($which && !$always_use_bundled_cmd) {
        $shared{$cmd} = [ $which ];
      }
      else {
        require AnyEvent::FTP; # dist_file needs this loaded so it can find it in %INC
        $shared{$cmd} = [
          $^X,  # use the same Perl
          dist_file 'AnyEvent-FTP', 'ppt/' . $cmd . '.pl',
        ];
      }
    }

    return @{ $shared{$cmd} }, @args;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Context::FSRW - FTP Server client context class with full read/write access

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use AnyEvent::FTP::Server;

 my $server = AnyEvent::FTP::Server->new(
   default_context => 'AnyEvent::FTP::Server::Context::FSRW',
 );

=head1 DESCRIPTION

This class provides a context for L<AnyEvent::FTP::Server> which uses the
actual filesystem to provide storage.

=head1 SUPER CLASS

This class inherits from

L<AnyEvent::FTP::Server::Context::FS>

=head1 ROLES

This class consumes these roles:

=over 4

L<AnyEvent::FTP::Server::Role::TransferPrep>

=back

=head1 COMMANDS

In addition to the commands provided by the above roles,
and super class, this context provides these FTP commands:

=over 4

=item RETR

=item NLST

=item LIST

=item STOR

=item APPE

=item STOU

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
