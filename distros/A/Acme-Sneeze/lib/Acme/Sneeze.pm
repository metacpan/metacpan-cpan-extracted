package Acme::Sneeze;

use strict;
our $VERSION = '0.02';

use Exporter::Lite;
our @EXPORT = qw(sneeze);

sub sneeze {
    my $self = shift;
    my $pkg  = caller;
    bless $self, $pkg;
}

1;
__END__

=head1 NAME

Acme::Sneeze - Bless you

=head1 SYNOPSIS

  package Your::Object;
  use Acme::Sneeze;

  package Others;

  my $object = Your::Object->new;
  $object->sneeze;    # "bless you!"

  print ref($object); # will print "Others"

=head1 DESCRIPTION

When you sneeze in America (or other English speaking countries),
you'll be blessed. But the problem is that they say "Bless you"
without the 2nd parameter: the package name.

So with Acme::Sneeze, your object will have I<sneeze> method, and when
you sneeze you'll be automatically blessed to the current package.

=head1 TODO

=head2 LOCALIZATION

In Japan, sneezing twice implies that "someone is talking about you." I
guess I<Acme::Sneeze> should be localized to increment reference count
of the object if the users locale is set to JP.

In Poland, the common response I<Sto lat> translates as I<Hundred
years>, wishing hundred years of health to the sneezer.
I<Acme::Sneeze> should wrap I<CORE::time> in Poland maybe.

More interesting stories about different reactions to sneezing in
different countries are available at L<http://en.wikipedia.org/wiki/Sneeze>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Bless_you>

=cut
