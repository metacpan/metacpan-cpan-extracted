package AnyEvent::FTP::Server::Context::FS;

use strict;
use warnings;
use 5.010;
use Moo;
use File::chdir;
use File::Spec;

extends 'AnyEvent::FTP::Server::Context';

# ABSTRACT: FTP server context that uses real file system (no transfers)
our $VERSION = '0.17'; # VERSION


with 'AnyEvent::FTP::Server::Role::Auth';
with 'AnyEvent::FTP::Server::Role::Help';
with 'AnyEvent::FTP::Server::Role::Old';
with 'AnyEvent::FTP::Server::Role::Type';


sub cwd
{
  my($self, $value) = @_;
  $self->{cwd} = $value if defined $value;
  $self->{cwd} //= '/';
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

  my $dir = $req->args;

  eval {
    die unless $dir;
    use autodie;
    local $CWD = $self->cwd;
    $CWD = $dir;
    $self->cwd($CWD);
    $con->send_response(250 => 'CWD command successful');
  };
  $con->send_response(550 => 'CWD error') if $@;

  $self->done;
}


sub help_cdup { 'CDUP' }

sub cmd_cdup
{
  my($self, $con, $req) = @_;

  eval {
    use autodie;
    local $CWD = $self->cwd;
    $CWD = File::Spec->updir;
    $self->cwd($CWD);
    $con->send_response(250 => 'CDUP command successful');
  };
  $con->send_response(550 => 'CDUP error') if $@;

  $self->done;
}


sub help_pwd { 'PWD' }

sub cmd_pwd
{
  my($self, $con, $req) = @_;

  my $cwd = $self->cwd;
  if($^O eq 'MSWin32')
  {
    (undef,$cwd) = File::Spec->splitpath($cwd, 1);
    $cwd =~ s{\\}{/}g;
  }
  $con->send_response(257 => "\"$cwd\" is the current directory");
  $self->done;
}


sub help_size { 'SIZE <sp> pathname' }

sub cmd_size
{
  my($self, $con, $req) = @_;

  eval {
    use autodie;
    local $CWD = $self->cwd;
    if(-f $req->args)
    {
      my $size = -s $req->args;
      $con->send_response(213 => $size);
    }
    elsif(-e $req->args)
    {
      $con->send_response(550 => $req->args . ": not a regular file");
    }
    else
    {
      die;
    }
  };
  if($@)
  {
    $con->send_response(550 => $req->args . ": No such file or directory");
  }
  $self->done;
}


sub help_mkd { 'MKD <sp> pathname' }

sub cmd_mkd
{
  my($self, $con, $req) = @_;

  my $dir = $req->args;
  eval {
    use autodie;
    local $CWD = $self->cwd;
    mkdir $dir;
    $con->send_response(257 => "Directory created");
  };
  $con->send_response(550 => "MKD error") if $@;
  $self->done;
}


sub help_rmd { 'RMD <sp> pathname' }

sub cmd_rmd
{
  my($self, $con, $req) = @_;

  my $dir = $req->args;
  eval {
    use autodie;
    local $CWD = $self->cwd;
    rmdir $dir;
    $con->send_response(250 => "Directory removed");
  };
  $con->send_response(550 => "RMD error") if $@;
  $self->done;
}


sub help_dele { 'DELE <sp> pathname' }

sub cmd_dele
{
  my($self, $con, $req) = @_;

  my $file = $req->args;
  eval {
    use autodie;
    local $CWD = $self->cwd;
    unlink $file;
    $con->send_response(250 => "File removed");
  };
  $con->send_response(550 => "DELE error") if $@;
  $self->done;
}


sub help_rnfr { 'RNFR <sp> pathname' }

sub cmd_rnfr
{
  my($self, $con, $req) = @_;

  my $path = $req->args;

  if($path)
  {
    eval {
      local $CWD = $self->cwd;
      if(!-e $path)
      {
        $con->send_response(550 => 'No such file or directory');
      }
      elsif(-w $path)
      {
        $self->rename_from($path);
        $con->send_response(350 => 'File or directory exists, ready for destination name');
      }
      else
      {
        $con->send_response(550 => 'Permission denied');
      }
    };
    if(my $error = $@)
    {
      warn $error;
      $con->send_response(550 => 'Rename failed');
    }
  }
  else
  {
    $con->send_response(501 => 'Invalid number of arguments');
  }
  $self->done;
}


sub help_rnto { 'RNTO <sp> pathname' }

sub cmd_rnto
{
  my($self, $con, $req) = @_;

  my $path = $req->args;

  if(! defined $self->rename_from)
  {
    $con->send_response(503 => 'Bad sequence of commands');
  }
  elsif(!$path)
  {
    $con->send_response(501 => 'Invalid number of arguments');
  }
  else
  {
    eval {
      local $CWD = $self->cwd;
      if(! -e $path)
      {
        rename $self->rename_from, $path;
        $con->send_response(250 => 'Rename successful');
      }
      else
      {
        $con->send_response(550 => 'File already exists');
      }
    };
    if(my $error = $@)
    {
      warn $error;
      $con->send_response(550 => 'Rename failed');
    }
  }
  $self->done;
}


sub help_stat { 'STAT [<sp> pathname]' }

sub cmd_stat
{
  my($self, $con, $req) = @_;

  my $path = $req->args;

  if($path)
  {
    do {
      local $CWD = $self->cwd;
      if(-d $path)
      {
        $con->send_response(211 => "it's a directory");
      }
      elsif(-f $path)
      {
        $con->send_response(211 => "it's a file");
      }
      else
      {
        $con->send_response(450 => 'No such file or directory');
      }
    };
  }
  else
  {
    # TODO: did I have a good reason for making this
    # not be an error?
    $con->send_response(211 => "it's all good.");
  }
  $self->done;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Context::FS - FTP server context that uses real file system (no transfers)

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 use AnyEvent::FTP::Server;
 
 my $server = AnyEvent::FTP::Server->new(
   default_context => 'AnyEvent::FTP::Server::Context::FS',
 );

=head1 DESCRIPTION

This is the base class for L<AnyEvent::FTP::Server::Context::FSRO> and
L<AnyEvent::FTP::Server::Context::FSRW>.

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

=head2 cwd

 my $dir = $context->cwd;

The current working directory as a string.

=head2 rename_from

 my $filename = $context-E<gt>rename_from;

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
