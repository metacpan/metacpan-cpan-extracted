#$Id: Deep.pm 25 2005-09-11 09:48:14Z kentaro $

package Class::AutoAccess::Deep;

use strict;

use Carp ();

our $AUTOLOAD;
our $VERSION = '0.02';

sub new {
    my ($class, $fields) = @_;

    _croak('argument must be passed in as hashref')
        unless defined $fields || ref $fields eq 'HASH';

    return bless $fields, $class;
}

sub AUTOLOAD {
    my $self = shift;
    (my $field = $AUTOLOAD) =~ s/.*:://;

    return if $field eq 'DESTROY';

    # XXX
    # croaks when you attempt to access an undefined field
    # do you need this feature?
    _croak("Field $field does not exists")
        unless exists $self->{$field};

    if (@_) {
        $self->{$field} = _get_linkedobj($_[0]);
    }
    else {
        $self->{$field} = _get_linkedobj($self->{$field});
    }

    return $self->{$field};
}

sub _get_linkedobj {
    my $value= shift;

    if (ref($value) eq 'HASH'){
        return __PACKAGE__->new($value);
    }
    else {
        return $value;
    }
}

sub _croak {
    my $msg = shift;
    Carp::croak($msg);

    return;
}

1;

__END__

=head1 NAME

Class::AutoAccess::Deep - automatically creates the accessors reach deep inside the field


=head1 SYNOPSIS

  package MyClass;

  # inherit Class::AutoAccess::Deep and that's all
  use base qw(Class::AutoAccess::Deep);

  sub to_check {
      # write your own processing code...
  }

  package main;

  $data = {
      foo      => undef,
      bar      => {
          baz  => undef,
      },
      to_check => undef,
  };

  my $obj = MyClass->new($data);

  # now, you can access the fields as described below
  $obj->foo('new value');        # set "new value"
  my $foo = $obj->foo;           # get "new value"

  # you can access the field chain deeply
  # by joining field name with '->'
  $obj->bar->baz('other value'); # set "other value"
  my $bar_baz = $obj->bar->baz;  # get "other value"

  # your own method called correctly
  my $value = $obj->to_check;

=head1 DESCRIPTION

Class::AutoAccess::Deep is the base class for automated accessors implementation. You can access deep inside the object fields to call the method named by joining the object field name with '->' operator.

=head1 METHOD

=head2 new ( I<\%fields> )

=over 4

  my $obj = MyClass->new(\%fields);

Creates and returns new object. It takes a hashref which is used to initialize the object. If you don't like it, override it.

=back

=head1 EXCEPTION

When you attempt to access the undefined field, Class::AutoAccess::Deep object throws exception using Carp::croak.

=head1 TODO

=over 4

=item * Store the accessors which is called once into somewhere for performance reason

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Makamaka, L<http://www.donzoko.net/>

=item * Naoya Ito, L<http://d.hatena.ne.jp/naoya/>

=item * Yappo, L<http://blog.yappo.jp/>

=item * YAMASHINA Hio, L<http://fleur.hio.jp/>

=item * Topia, L<http://www.clovery.jp/>

=back

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
