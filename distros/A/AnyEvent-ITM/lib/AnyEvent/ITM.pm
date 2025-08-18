package AnyEvent::ITM;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Debug ITM/SWD stream deserializer for AnyEvent
$AnyEvent::ITM::VERSION = '0.100';
use strict;
use warnings;
use bytes;

use AnyEvent;
use AnyEvent::Handle;
use Carp qw( croak );
use ITM;
use Fcntl qw(O_RDONLY O_RDWR O_NONBLOCK O_NOCTTY);
use AnyEvent::Util qw(run_cmd portable_pipe);

AnyEvent::Handle::register_read_type(itm => sub {
  my ( $self, $cb ) = @_;
  sub {
    if (defined $_[0]{rbuf}) {
      my $first = substr($_[0]{rbuf},0,1);
      my $len = length($_[0]{rbuf});
      my $f = ord($first);
      my $header = itm_header($first);
      if ($header) {
        my $size = $header->{size} ? $header->{size} : 0;
        my $payload = substr($_[0]{rbuf},1,$size);
        if (defined $payload && length($payload) == $size) {
          my $itm = itm_parse($header,$size ? ($payload) : ());
          $_[0]{rbuf} = substr($_[0]{rbuf},$size + 1);
          $cb->( $_[0], $itm );
          return 1;          
        }
        return 0;
      } else {
        croak sprintf("unknown packet type");
      }
    }
    return 0;
  };
});

sub _ts {
  my @t = localtime;
  return sprintf "%04d-%02d-%02d %02d:%02d:%02d",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0];
}

sub _print_ts {
  my ( $label, $line ) = @_;
  chomp $line;
  if ($label eq '2>') {
    print STDERR _ts()." $label $line\n";
  } else {
    print STDOUT _ts()." $label $line\n";
  }
};

sub handle {
  my ( $class, $file, $payload_sub, $cv ) = @_;

  my $has_cv = defined $cv ? 1 : 0;

  $cv = AE::cv unless $has_cv;

  # Choose flags so open won't block
  my $flags;
  if (-p $file) {
    $flags = O_RDWR | O_NONBLOCK;
  } else {
    $flags = O_RDONLY | O_NONBLOCK;
    $flags |= O_NOCTTY if -c $file;
  }

  sysopen(my $fh, $file, $flags) or die "sysopen $file: $!";
  binmode($fh, ':raw');

  my $handle = AnyEvent::Handle->new(
    fh => $fh,
    on_error => sub {
      my ( $handle, $fatal, $message ) = @_;
      $handle->destroy;
      $cv->send("$fatal: $message");
    },
    on_eof => sub {
      my ( $handle ) = @_;
      $handle->destroy;
      $cv->send("EOF");
    },
    on_read => sub {
      my $handle = shift;
      $handle->push_read( itm => $payload_sub );
    },
  );

  $cv->recv unless $has_cv;

  return $handle;
}

sub _run_cmd {
  my ($class, @cmd) = @_;
  die "run_cmd: no command" unless @cmd;

  my ($out_r, $out_w) = portable_pipe;
  my ($err_r, $err_w) = portable_pipe;

  my $proc = run_cmd \@cmd, '>' => $out_w, '2>' => $err_w, close_all => 1;

  close $out_w;
  close $err_w;

  my %cmd = (
    cv   => AE::cv,
    proc => $proc,
  );

  $cmd{hout} = AnyEvent::Handle->new(
    fh      => $out_r,
    on_read => sub {
      my ($h) = @_;
      $h->push_read(line => sub {
        my ($h, $line) = @_;
        _print_ts('>', $line);
      });
    },
    on_eof   => sub { shift->destroy },
    on_error => sub { shift->destroy },
  );

  $cmd{herr} = AnyEvent::Handle->new(
    fh      => $err_r,
    on_read => sub {
      my ($h) = @_;
      $h->push_read(line => sub {
        my ($h, $line) = @_;
        _print_ts('2>', $line);
      });
    },
    on_eof   => sub { shift->destroy },
    on_error => sub { shift->destroy },
  );

  $proc->cb(sub {
    my $raw = shift->recv;                 # like $?
    my $code = ($raw >> 8) & 0xff;
    my $sig  = $raw & 0x7f;
    $cmd{exit_code} = $code;
    $cmd{signal}    = $sig if $sig;
    $cmd{cv}->send($code);
  });

  return \%cmd;  # keep this in scope; wait via $obj->{cv}->recv
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::ITM - Debug ITM/SWD stream deserializer for AnyEvent

=head1 VERSION

version 0.100

=head1 SYNOPSIS

  my $cv = AE::cv;
  my $handle = AnyEvent::ITM->handle($file, sub {
    my ( $handle, $itm ) = @_;
    if (ref $itm eq 'ITM::Instrumentation') {
      printf("[%u]%s", $itm->source, $itm->payload);
    }
  }, $cv);
  $cv->recv;

or without $cv, it will start its own and does $cv->recv on its own.

  AnyEvent::ITM->handle($file, sub { ... });

=head1 DESCRIPTION

Process ITM/SWO Debugging data.

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-anyevent-itm
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-anyevent-itm/issues

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-anyevent-itm>

  git clone https://github.com/Getty/p5-anyevent-itm.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
