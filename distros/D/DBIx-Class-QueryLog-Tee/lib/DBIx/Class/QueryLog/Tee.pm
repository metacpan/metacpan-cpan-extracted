package DBIx::Class::QueryLog::Tee;
$DBIx::Class::QueryLog::Tee::VERSION = '0.001001';
# ABSTRACT: Log to multiple QueryLogs at a time

use Moo;
use warnings NONFATAL => 'all';

use Sub::Name 'subname';

my @methods = qw(
   txn_begin txn_commit txn_rollback
   svp_begin svp_release svp_rollback
   query_start query_end
);
sub _valid_logger { !$_[0]->can($_) && return 0 for @methods; 1 }

use namespace::clean;

has _loggers => (
   is => 'ro',
   isa => sub {
      die "loggers has to be a hashref"
         unless ref $_[0] && ref $_[0] eq 'HASH';
      !_valid_logger($_[0]->{$_}) && die "\$loggers->{$_} does not point to a valid logger"
         for keys %{$_[0]};
   },
   default => sub { {} },
   init_arg => 'loggers',
);

sub add_logger {
   my ($self, $name, $logger) = @_;

   die "$name is not a valid logger" unless _valid_logger($logger);

   die "Logger $name is already in the list"
      if $self->_loggers->{$name};

   $self->_loggers->{$name} = $logger
}

sub remove_logger {
   my ($self, $name) = @_;

   die "unknown logger $name" unless $self->_loggers->{$name};

   delete $self->_loggers->{$name}
}

sub replace_logger {
   die "that is not a valid logger" unless _valid_logger($_[2]);

   $_[0]->_loggers->{$_[1]} = $_[2]
}

for my $method (@methods) {
   no strict 'refs';
   *{$method} = subname $method => sub {
      my $self = shift;

      $_->$method(@_) for
         map $self->_loggers->{$_},
         sort keys %{$self->_loggers};
   };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::QueryLog::Tee - Log to multiple QueryLogs at a time

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

 my $ql = DBIx::Class::QueryLog->new;
 $schema->storage->debugobj(
    DBIx::Class::QueryLog::Tee->new(
       loggers => {
          '1-original' => $schema->storage->debugobj,
          '2-current'  => $ql,
       },
    ),
 );

Now all queries should be logged to both loggers.

=head1 DESCRIPTION

Sometimes you want to see what queries you are running without having to
look at database logs or the console that your app is running on (if it
even is running on a console.)  But what if you want to add tooling to,
eg, count queries per web request, and B<also> see the queries being
run on the console?  This module solves that problem.

Fundamentally it has a HashRef of logger objects, and passes all of the
logging commands through, in the order of the keys.  So if you need a
logger to be first, make sure it has the "earliest" key.

=head1 METHODS

=head2 C<new>

Optionally takes a C<loggers> hashref.  The values must each be a
L</LOGGER>.

=head2 C<add_logger>

Takes a name and a L</LOGGER>.  Throws an exception if there is already
a logger with the passed name.

=head2 C<remove_logger>

Takes a name.  Throws an exception if there is no logger with the
passed name.

=head2 C<replace_logger>

Takes a name and a L</LOGGER>.  Will replace a logger with the same name, or
just add it if there wasn't already one there.

=head1 LOGGER

A logger is defined as an object that has the following methods:

   txn_begin txn_commit txn_rollback
   svp_begin svp_release svp_rollback
   query_start query_end

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
