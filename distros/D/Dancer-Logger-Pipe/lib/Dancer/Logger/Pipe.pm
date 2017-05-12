package Dancer::Logger::Pipe;

use strict;
use warnings;
use Carp;
use base 'Dancer::Logger::Abstract';
use Dancer::Config 'setting';
use IO::Handle;

our $VERSION = '0.01';

sub init {
    my ($self) = @_;

    my $pipe    = setting('pipe')  || croak "Missing pipe settings";
    my $command = $pipe->{command} || croak "Missing pipe command setting";

    open( my $fh, '|-', $command)
        || croak "Unable to open pipe: $!";

    $fh->autoflush(1);

    $self->{fh}          = $fh;
}

sub _log {
    my ( $self, $level, $message ) = @_;
    my $fh = $self->{fh};

    return unless ref $fh && $fh->opened;

    $fh->print( $self->format_message( $level => $message ) )
        or carp "writing logs to pipe failed: $!";
}

1;

__END__

=head1 NAME

Dancer::Logger::Pipe - pipe-based logging engine for Dancer

=head1 SYNOPSIS

Used to pipe the logs from Dancer. This requires some additional settings.

  logger: pipe
  pipe:
    command:     "/usr/bin/cronolog /var/log/dancer/%Y/%m/%d/dancer.log"

=head1 DESCRIPTION

This is a pipe-based logging engine that allows you to pipe your log output

=head1 METHODS

=head2 init

This method is called when C<< ->new() >> is called.
It opens the pipe for writing.

=head2 _log

Writes the log message to the pipe.

=head1 AUTHOR

Moshe Good

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Moshe Good.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

