package AnyEvent::DBI::Abstract;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use parent qw(AnyEvent::DBI);
use Carp ();
use SQL::Abstract;
no strict 'refs';

sub abstract {
    my $self = shift;
    $self->{_DBI_abstract} ||= SQL::Abstract->new;
}

for my $method (qw( select insert update delete )) {
    *$method = sub {
        my($self, @args) = @_;
        my $cb = pop @args;
        my($stmt, @bind) = $self->abstract->$method(@args);
        $self->exec($stmt, @bind, $cb);
    };
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::DBI::Abstract - AnyEvent::DBI + SQL::Abstract

=head1 SYNOPSIS

  use AnyEvent::DBI::Abstract;

  my $dbh = AnyEvent::DBI::Abstract->new($dsn, $user, $pass);

  $dbh->select($table, \@fields, \%where, \@order, sub {
      my($dbh, $rows, $rv) = @_;
      # ...
  });

  $dbh->insert($table, \%fieldvals, sub {
      my($dbh, undef, $rv) = @_;
      # ...
  });

  $dbh->update($table, \%fieldvals, \%where, sub {
      my($dbh, undef, $rv) = @_;
      # ...
  });

  $dbh->delete($table, \%where, sub {
      my($dbh, undef, $rv) = @_;
      # ...
  });

=head1 DESCRIPTION

AnyEvent::DBI::Abstract is a subclass of AnyEvent::DBI that has
methods to wrap SQL::Abstract methods into C<exec>. See
L<SQL::Abstract> for the parameters to the methods and
L<AnyEvent::DBI> for the callback interface.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::DBI> L<SQL::Abstract>

=cut
