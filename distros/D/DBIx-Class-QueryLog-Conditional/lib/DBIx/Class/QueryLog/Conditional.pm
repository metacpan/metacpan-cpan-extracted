package DBIx::Class::QueryLog::Conditional;
$DBIx::Class::QueryLog::Conditional::VERSION = '0.001000';
# ABSTRACT: Disable QueryLogger instead of all query logging

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

has _logger => (
   is => 'ro',
   isa => sub { die 'not a valid logger' unless _valid_logger($_[0]) },
   init_arg => 'logger',
   required => 1,
);

has enabled => (
   is => 'rw',
   default => 1,
);

has _enabled_method => (
   is => 'ro',
   init_arg => 'enabled_method',
   default => sub {
      sub { shift->enabled }
   },
);

for my $method (@methods) {
   no strict 'refs';
   *{$method} = subname $method => sub {
      my $self = shift;

      my $m = $self->_enabled_method ;
      return unless $self->$m;

      $self->_logger->$method(@_);
   };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::QueryLog::Conditional - Disable QueryLogger instead of all query logging

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

 my $ql = DBIx::Class:::QueryLog->new;
 $schema->storage->debugobj(
    DBIx::Class:::QueryLog::Tee->new(
         loggers => {
            new      => $ql,
            original => DBIx::Class::QueryLog::Conditional->new(
               logger => $self->storage->debugobj,
               enabled_method => sub { $ENV{DBIC_TRACE} },
            ),
         },
    ),
 );
 $schema->storage->debug(1);

Now the original storageobj is enabled and disabled based on the standard env
var.

=head1 DESCRIPTION

When you use L<DBIx::Class::QueryLog::Tee> you will likely find that
suddenly you are logging everything.  Before C<::Tee> came along your
console was inconsolable, dispondant; you never heard from it again.
After using C<::Tee> suddenly your silent, morose query log became manic.
It woudln't shut up!  This was not what you bargained for...

C<DBIx::Class::QueryLog::Conditional> is part of The Final Equation.
Instead of no noise, or all noise, C<::Conditional> is the bear that
gives you just the right amount and temperature of porridge.

=head1 METHODS

=head2 C<new>

Requires a C<logger> that must be a L</LOGGER>.  Can optionally take
either C<enabled> or C<enabled_method>.

C<enabled> is a simple bool, defaulting to true.

C<enabled_method> is a code reference called as a method.  It defaults to
checking L</enabled>.  A good alternate is proposed in the L</SYNOPSIS>.

=head2 C<enabled>

A simple helper attribute.  Defaults to true, can be set to false to
turn off your logger via code.

=head1 LOGGER

A logger is defined as an object that has the following methods:

   txn_begin txn_commit txn_rollback
   svp_begin svp_release svp_rollback
   query_start query_end

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
