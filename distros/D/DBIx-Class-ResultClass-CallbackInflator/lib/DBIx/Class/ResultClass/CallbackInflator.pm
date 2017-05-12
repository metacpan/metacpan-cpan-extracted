package DBIx::Class::ResultClass::CallbackInflator;

our $VERSION = '0.003';
use Moo;

has 'callback' => (
  is=>'ro',
  isa=>sub { ref($_[0]) eq 'CODE' },
  required=>1);

has 'args' => (
  is=>'ro',
  isa=>sub { ref($_[0]) eq 'ARRAY' },
  default=>sub { [] },
  required=>1);

sub inflate_result {
  my ($self, $result_source, $columndata, $prefetcheddata) = @_;
  my @args = ($self->callback, $result_source, $columndata, $prefetcheddata, @{$self->args});
  local %_ = %{$columndata};
  return $self->callback->(@args);
}

1;

=head1 NAME

DBIx::Class::ResultClass::CallbackInflator - Easier way to make a quick, custom inflator

=head1 SYNOPSIS

    use DBIx::Class::ResultClass::CallbackInflator;

    my $result_instance = DBIx::Class::ResultClass::CallbackInflator
      ->new(callback=>$callback, args=>\@args);

    my $person_resultset = $schema
        ->resultset('Person')
        ->resultclass($result_instance);

    # Alternatively
    my $person_resultset = $schema
        ->resultset('Person')
        ->search(+{}, +{result_class=>$result_instance});

=head1 DESCRIPTION

You might wish to review L<DBIx::Class::ResultSet::CallbackInflator> which is probably
the most easy way to actually make use of this in a resultset.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 callback

This is the callback with receives the row level data for the resultset as it gets it
from the database and is responsible for returning a reference to a version of that
data suitable for a user.

=head2 args

Arguments passed to the callback.

=head1 METHODS

This component defines the following methods.

=head2 inflate_result

Provides the method needed to call table data on your custom callback (with any passed
arguments).

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

With thanks to mst for the original code suggestion!

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::ResultClass::HashRefInflator>.

=head1 COPYRIGHT & LICENSE

Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
