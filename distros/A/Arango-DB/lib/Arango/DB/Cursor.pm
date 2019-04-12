# ABSTRACT: ArangoDB Cursor object
package Arango::DB::Cursor;
$Arango::DB::Cursor::VERSION = '0.005';
use warnings;
use strict;

use Data::Dumper;

sub _new {
  my ($class, %opts) = @_;
  my $self = { arango => $opts{arango}, database => $opts{database} };

  my $ans = $self->{arango}->_api('create_cursor', \%opts);

  return bless { %$ans, %$self, __current => 0 } => $class;
}

sub next {
  my $self = shift;

  if (!$self->{error} && $self->{__current} == 0) {
    $self->{__current}++;
    return $self->{result};
  }

  if ($self->{hasMore}) {
    my $ans = $self->{arango}->_api('cursor_next', { database => $self->{database}, id => $self->{id} });
    if (!$ans->{error}) {
      $self->{hasMore} = $ans->{hasMore};
      return $ans->{result};
    }
  }

  return undef;
}

sub has_more {
  my ($self) = @_;
  return $self->{hasMore};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::DB::Cursor - ArangoDB Cursor object

=head1 VERSION

version 0.005

=head1 USAGE

This class should not be created directly. The L<Arango::DB> module is responsible for
creating instances of this object.

C<Arango::DB::Cursor> answers to the following methods:

=head1 METHODS

=over 4

=item C<next>

Returns the next results. On the first call, returns the results
obtained from the first query request.  Subsequent requests will try
to gather more hits if they exists, and the query id is still alive.

=item C<has_more>

Returns a boolean stating if there are more results to be fetched.

=back

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
