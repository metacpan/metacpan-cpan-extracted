package Attribute::Static;

use strict;
use warnings;

our $VERSION = '0.02';

use Attribute::Handlers;

sub UNIVERSAL::Static : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my $meth = *{$symbol}{NAME};
    no warnings 'redefine';
    *{$symbol} = sub {
        my $class = $_[0];
        if ($class ne $package) {
            require Carp;
            Carp::croak "$meth() is a static method of $package!";
        }
        goto &$referent;
    };
}

1;
__END__

=head1 NAME

Attribute::Static - implementing static method with attributes

=head1 SYNOPSIS

  package Foo;
  use Attribute::Static;
  sub new {
      my $class = shift;
      bless {}, $class;
  }
  sub bar : Static {
      my $class = shift;
  }

  Foo->bar;  # OK
  my $foo = Foo->new;
  $foo->bar; # NG

=head1 DESCRIPTION

Attribute::Static implements something like static methods in Java.

=head1 ATTRIBUTES

=over 4

=item Static

  sub foo : Static { }

must be called without instance.

=back

=head1 SEE ALSO

L<Attribute::Handlers>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jiro Nishiguchi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
