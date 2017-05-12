package DB::Evented;

use 5.006;
use strictures;
use AnyEvent::DBI;

=head1 NAME

DB::Evented - A pragmatic DBI like evented module.

=cut

our $VERSION = '0.06';
our $handlers = [];

=head1 SYNOPSIS

Doing selects in synchronise order is not always the most efficient way to interact with the 
Database. 

  use DB::Evented;

  my $evented = DB::Evented->new("DBI:SQLite2:dbname=$dname", "","");

  my $results;
  $evented->selectcol_arrayref(
    q{
      select
        test1,
        test2
      from
        test
    },
    { 
      Columns => [1,2],
      response => sub {
          $results->{result1} = shift;
      }		
    }
  );
  
  $evented->selectrow_hashref(
    q{
      select
        test1,
        test2
      from
        test
    },
    {
      response => sub {
        $results->{result2} = shift;
      }
    }
  );

  $evented->execute_in_parallel;

=head1 STATIC METHODS

=head2 new ($connection_str, $username, $pass, %dbi_args )

In order to initialize a DB::Evented object a connection_str is most likely required.
See AnyEvent::DBI for more information.

=cut

sub new {
  my $class = shift;
  $class ||= ref $class;
  my ($connection_str, $username, $pass, %dbi_args) = @_;
  return bless {
    connection_str => $connection_str,
    username => $username,
    pass => $pass,
    dbi_args => \%dbi_args,
    _queue => [],
  }, $class;
}

=head1 INSTANCE METHODS

=head2 any_event_handler

This will return an AnyEvent::DBI handler. The key difference between this handler and DBI is that it's using AnyEvent
under the hood. What does this mean? It means that if you use an AnyEvent::DBI method it will run asynchronously.

=cut
sub any_event_handler {
  my $self = shift;
  return AnyEvent::DBI->new($self->{connection_str}, $self->{username}, $self->{pass}, %{$self->{dbi_args}}, on_error => sub {
    $self->clear_queue;
    warn "DBI Error: $@ at $_[1]:$_[2]\n";
  });
}

=head2 clear_handlers

Clears all handlers

=cut

sub clear_handlers {
  $handlers = [];
}

=head2 clear_queue

Clears the queue of any db todos

=cut

sub clear_queue {
  $_[0]->{_queue} = undef;
}

=head2 execute_in_parallel

Will execute all of the queued statements in parallel. This will create a pool of handlers and cache them if necessary.

=cut

sub execute_in_parallel {
  my $self = shift;
  if ( scalar @{$self->{_queue}} ) {
    # Setup a pool of handlers
    # TODO: Make this more intelligent to shrink
    if ( ! scalar @{$handlers} || ( scalar @{$handlers} < scalar @{$self->{_queue}} )) {
      while ( scalar @{$handlers} < scalar @{$self->{_queue}} ) {
        push @{$handlers}, $self->any_event_handler;
      }
    }
    $self->{cv} = AnyEvent->condvar;
    my $count = 0;
    for my $item ( @{$self->{_queue}} ) {
      my $cb = pop @$item;
      my $callback_wrapper = sub { 
        my ($dbh, $result) = @_;
        $cb->($result, $dbh);
        $self->{cv}->end;
      };
      my $req_method = pop @$item;
      my $line = pop @$item;
      my $file = pop @$item;
      $self->{cv}->begin;
      $handlers->[$count]->_req($callback_wrapper, $line, $file, $req_method, @$item);
      $count++;
    }
    $self->{cv}->recv;
    delete $self->{cv};
    $self->clear_queue;
  }
  return;
}

sub _add_to_queue {
  my ( $self, $sql, $attr, $key_field, @args) = @_;

  my $cb = delete $attr->{response};
  my $item = [$sql, $attr, $key_field, @args, __PACKAGE__ . '::_req_dispatch', $cb]; 

  push @{$self->{_queue}}, $item;
}

sub _req_dispatch {
  my (undef, $st, $attr, $key_field, @args) = @{+shift};
  my $method_name = pop @args;
  my $result = $AnyEvent::DBI::DBH->$method_name($key_field ? ($st, $key_field, $attr, @args) : ($st, $attr, @args) );
  [1, $result ? $result : undef];
}

=head2 selectall_arrayref ($sql, \%attr, @binds )

This method functions in the same way as DBI::selectall_arrayref. The key difference
being it delays the execution until execute_in_parallel has been called. The results
can be accessed in the response attribute call back 

=cut

=head2 selectall_hashref ($sql, $key_field, \%attr, @binds )

This method functions in the same way as DBI::selectall_hashref. The key difference
being it delays the execution until execute_in_parallel has been called. The results
can be accessed in the response attribute call back 

=cut

=head2 selectrow_arrayref ($sql, \%attr, @binds )

This method functions in the same way as DBI::selectrow_arrayref. The key difference
being it delays the execution until execute_in_parallel has been called. The results
can be accessed in the response attribute call back 

=cut

=head2 selectrow_hashref ($sql, \%attr, @binds )

This method functions in the same way as DBI::selectrow_hashref. The key difference
being it delays the execution until execute_in_parallel has been called. The results
can be accessed in the response attribute call back 

=cut

for my $method_name ( qw(selectrow_hashref selectcol_arrayref selectall_hashref selectall_arrayref) ) {
  no strict 'refs';
  *{$method_name} = sub {
    my $self = shift;
    my ($sql, $key_field, $attr, @args) = (shift, ($method_name eq 'selectall_hashref' ? (shift) : (undef)), shift, @_);
    $self->_add_to_queue($sql, $attr, $key_field, @args, $method_name, (caller)[1,2]);
  };
}

# TODO: Investigate if this is the bet way to handle this.
# The child processes are technically held by AnyEvent::DBI
# by clearing the known handlers these children *should* be reaped
sub DESTROY {
  my $error = do {
    local $@;
    eval {
      DB::Evented->clear_handlers;
    };
    $@;
  };
  $? = 0 unless $error;
}

=head1 AUTHOR

Logan Bell, C<< <logie at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DB::Evented

You can also look for information at:

=head1 ACKNOWLEDGEMENTS

Aaron Cohen and Belden Lyman.

=head1 LICENSE

Copyright (c) 2013 Logan Bell and Shutterstock Inc (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of DB::Evented
