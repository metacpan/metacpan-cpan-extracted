package Clustericious::Admin::RemoteHandler;

use strict;
use warnings;
use 5.010;
use AE;
use AnyEvent::Open3::Simple 0.76;

our $VERSION = '1.11'; # VERSION

sub new
{
  my($class, %args) = @_;
  
  # args: prefix, clad, user, host, payload
  
  my $self = bless {
    prefix  => $args{prefix},
    clad    => $args{clad},
    cv      => AE::cv,
    summary => $args{clad}->summary,
  }, $class;
  
  my $clad = $args{clad};
  
  # TODO: handle the same host multiple times
  if($clad->log_dir)
  {
    my $fn = $clad->log_dir->file($args{prefix} . ".log");
    open(my $fh, '>', "$fn")
      || die "unable to write to $fn $!";
    $self->{logfile} = $fh;
    $self->{logfilename} = $fn;
  }
  
  my $done = $self->{cv};
  
  my $ipc = AnyEvent::Open3::Simple->new(
    on_start => sub {
      my($proc, $program, @args) = @_;
      $self->print_line(star => "% $program @args") if $clad->verbose;
    },
    on_stdout => sub {
      my($proc, $line) = @_;
      $self->print_line(out => $line);
    },
    on_stderr => sub {
      my($proc, $line) = @_;
      $self->print_line(err => $line);
    },
    on_exit => sub {
      my($proc, $exit, $signal) = @_;
      $self->print_line(exit => $exit) if ($self->summary && !$signal) || $exit;
      $self->print_line(sig  => $signal) if $signal;
      $clad->ret(2) if $exit || $signal;
      $self->cleanup;
    },
    on_error => sub {
      my($error) = @_;
      $self->print_line(fail => $error);
      $clad->ret(2);
      $self->cleanup;
    },
  );
  
  $ipc->run(
    $clad->ssh_command,
    $clad->ssh_options,
    $clad->ssh_extra,
    ($args{user} ? ('-l' => $args{user}) : ()),
    $args{host},
    $clad->server_command,
    \$args{payload},
  );

  $self;
}

sub clad    { shift->{clad}    }
sub prefix  { shift->{prefix}  }
sub summary { shift->{summary} }
sub logfile { shift->{logfile} }
sub logfilename { shift->{logfilename} }

sub cleanup
{
  my($self) = @_;
  $self->logfile->close if $self->logfile;
  $self->{cv}->send;
}

sub color
{
  my($self) = @_;
  $self->{color} //= $self->clad->next_color;
}

sub is_color
{
  my($self) = @_;
  $self->{is_color} //= $self->clad->color;
}

sub print_line
{
  my($self, $code, $line) = @_;

  my $fh = $self->logfile;  
  printf $fh "[%-4s] %s\n", $code, $line
    if $fh;
  
  my $last_line = $code =~ /^(exit|sig|fail)$/;
  
  return if $self->summary && ! $last_line;
  
  if($last_line && $line ne '0')
  {
    print Term::ANSIColor::color($self->clad->fail_color) if $self->is_color;
  }
  else
  {
    print Term::ANSIColor::color($self->color) if $self->is_color;
  }

  printf "[%@{[ $self->clad->host_length ]}s %-4s] ", $self->prefix, $code;

  if(! $last_line)
  {
    if($code eq 'err')
    {
      print Term::ANSIColor::color($self->clad->err_color) if $self->is_color;
    }
    else
    {
      print Term::ANSIColor::color('reset') if $self->is_color;
    }
  }
  
  print $line;
  
  if($last_line || $code eq 'err')
  {
    print Term::ANSIColor::color('reset') if $self->is_color;
  }
  
  print "\n";
  
  if($fh && $last_line && $line ne '0')
  {
    print ' ' x ($self->clad->host_length +8), "see @{[ $self->logfilename ]}\n";
  }
}

sub cv { shift->{cv} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Admin::RemoteHandler

=head1 VERSION

version 1.11

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
