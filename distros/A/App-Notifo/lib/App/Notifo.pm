package App::Notifo;
BEGIN {
  $App::Notifo::VERSION = '0.001';
}

# ABSTRACT: command-line tool to send a notification to notifo.com

use strict;
use warnings;
use WebService::Notifo;
use Getopt::Long;
use Pod::Usage;

sub new { return bless {}, shift }


sub run {
  my $self = shift;

  $self->_parse_options();

  ## No text, no notification
  unless ($self->{opts}{msg}) {
    $self->_out('No text found, no notification sent');
    exit(1);
  }

  my $res = $self->_send_notification;
  exit(0) if $res->{status} eq 'success';

  $self->_out('Error: ', $res->{response_message});
  exit(1);
}

sub _send_notification {
  my ($self) = @_;
  my $opts = $self->{opts};

  my $n = WebService::Notifo->new(_slice($opts, qw(api_key user)));
  return $n->send_notification(_slice($opts, qw(to title uri label msg)));
}

sub _parse_options {
  my ($self) = @_;

  my %opts;
  $self->{opts} = \%opts;
  my $ok = GetOptions(
    \%opts,
    "help|?",
    "man",

    "quiet",

    "api_key|api-key|key|k=s",
    "user|u=s",
    "to|destination|t=s",
    "title|T=s",
    "uri|url|U=s",
    "label|l=s",
  ) || pod2usage(2);

  pod2usage(1) if $opts{help};
  pod2usage(-verbose => 2) if $opts{man};

  if (0 == @ARGV || (1 == @ARGV && $ARGV[0] eq '-')) {
    $opts{msg} = $self->_read_notification_text;
  }
  else {
    $opts{msg} = join(' ', @ARGV);
  }

  return \%opts;
}

sub _out {
  my $self = shift;

  return unless -t \*STDOUT;
  return if $self->{opts}{quiet};

  print join('', @_, "\n");
}

sub _read_notification_text {
  my ($self) = @_;

  $self->_out("Type the text of your notification.\n",
    "Enter CTRL-D to finish and send, CTRL-C to abort")
    if -t \*STDIN;

  return do { local $/; <> };
}

sub _slice {
  my $in = shift;
  my %out;

  for my $k (@_) {
    $out{$k} = $in->{$k} if exists $in->{$k};
  }

  return %out;
}

1;



=pod

=head1 NAME

App::Notifo - command-line tool to send a notification to notifo.com

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # See notifo --man

=head1 DESCRIPTION

The C<notifo> command line tool allows you to send notification to the
L<notifo.com service|http://notifo.com/>.

This module parses the command line options and call
L<WebService::Notifo/send_notification> to send the notification.

=head1 CONSTRUCTORS

=head2 new

Creates an empty C<App::Notifo> object.

=head1 METHODS

=head2 run

Parses the command line options and calls the L<WebService::Notifo> to
send the notification.

=head1 SEE ALSO

L<WebService::Notifo>, L<Protocol::Notifo>

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

