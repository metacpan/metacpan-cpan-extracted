package App::Environ;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.22';

use Carp qw( croak );

my %REGD_HANDLERS;
my %MODULES_IDX;


sub register {
  my $class        = shift;
  my $module_class = shift;
  my %handlers     = @_;

  unless ( defined $module_class ) {
    croak 'Module class must be specified';
  }

  unless ( exists $MODULES_IDX{$module_class} ) {
    $MODULES_IDX{$module_class} = {};
  }
  my $events_idx = $MODULES_IDX{$module_class};

  while ( my ( $event_name, $handler ) = each %handlers ) {
    next if exists $events_idx->{$event_name};

    $events_idx->{$event_name} = 1;
    unless ( exists $REGD_HANDLERS{$event_name} ) {
      $REGD_HANDLERS{$event_name} = [];
    }
    if ( $event_name =~ m/\:r$/ ) {
      unshift( @{ $REGD_HANDLERS{$event_name} }, $handler );
    }
    else {
      push( @{ $REGD_HANDLERS{$event_name} }, $handler );
    }
  }

  return;
}

sub send_event {
  my $class      = shift;
  my $event_name = shift;
  my $cb         = pop if ref( $_[-1] ) eq 'CODE';
  my @args       = @_;

  unless ( defined $event_name ) {
    croak 'Event name must be specified';
  }

  unless ( exists $REGD_HANDLERS{$event_name} ) {
    $cb->() if defined $cb;
    return;
  }

  my @handlers = @{ $REGD_HANDLERS{$event_name} };
  if ( defined $cb ) {
    $class->_process_async( \@handlers, \@args, $cb );
  }
  else {
    foreach my $handler (@handlers) {
      $handler->(@args);
    }
  }

  return;
}

sub _process_async {
  my $class    = shift;
  my $handlers = shift;
  my $args     = shift;
  my $cb       = shift;

  my $handler = shift @{$handlers};

  $handler->( @{$args},
    sub {
      my $err = shift;

      if ( defined $err ) {
        $cb->($err);
        return;
      }

      if ( @{$handlers} ) {
        $class->_process_async( $handlers, $args, $cb );
        return;
      }

      $cb->();
    }
  );

  return;
}

1;
__END__

=head1 NAME

App::Environ - Simple environment to build applications using service locator
pattern

=head1 SYNOPSIS

  use App::Environ;

  App::Environ->register( __PACKAGE__,
    initialize   => sub { ... },
    reload       => sub { ... },
    'finalize:r' => sub { ... },
  );

  App::Environ->send_event( 'initialize', qw( foo bar ) );
  App::Environ->send_event('reload');
  App::Environ->send_event( 'pre_finalize:r', sub {...} );
  App::Environ->send_event('finalize:r');

=head1 DESCRIPTION

App::Environ is the simple environment to build applications using service
locator pattern. Allows register different application components that provide
common resources.

=head1 METHODS

=head2 register( $class, \%handlers )

The method registers handlers for specified events. When some event have been
sent, registered event handlers will be processed in order in which they was
registered. If you want that event handlers have been processed in reverse
order, add postfix C<:r> to event name. All arguments that have been specified
in C<send_event> method (see below) are passed to called event handler. If in
the last argument is passed the callback, the handler must call it when
processing will be done. If the handler was called with callback and some error
occurred, the callback must be called with error message in first argument.

  App::Environ->register( __PACKAGE__,
    initialize => sub {
      my @args = @_;

      # handling...
    },
  );

=head2 send_event( $event [, @args ] [, $cb->( [ $err ] ) ] )

Sends specified event to App::Environ. All handlers registered for this event
will be processed. Arguments specified in C<send_event> method will be passed
to event handlers. If the callback is passed in the last argument, event
handlers will be processed in asynchronous mode.

  App::Environ->send_event( 'initialize', qw( foo bar ) );

  App::Environ->send_event( 'pre_finalize:r'
    sub {
      my $err = shift;

      if ( defined $err ) {
        # error handling...

        return;
      }

      # success handling...
    }
  );

=head1 SEE ALSO

L<App::Environ::Config>

Also see examples from the package to better understand the concept.

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
