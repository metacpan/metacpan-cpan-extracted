package Acme::Sneeze::JP;

use strict;
use 5.8.0;
our $VERSION = '0.01';

use Exporter::Lite;
our @EXPORT = qw(sneeze);

use Scalar::Util qw(refaddr);

our %talk;
sub sneeze {
    my $obj = shift;
    $talk{refaddr($obj)} = $obj; # someone is talking about you
}

1;
__END__

=head1 NAME

Acme::Sneeze::JP - Someone is talking about you

=head1 SYNOPSIS

  package Foo;
  use Acme::Sneeze::JP;

  {
    my $foo = Foo->new;
    $foo->sneeze;
  }

  # $foo is not GC-ed

=head1 DESCRIPTION

In Japan, sneezing means I<someone is talking about you>.

Acme::Sneeze::JP gives you I<sneeze> method, and when you object
sneezes, the reference count to the object is automatically
incremented. So your object won't be garbage collected until the
global destruction.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Acme::Sneeze>, L<http://ja.wikipedia.org/wiki/%E3%81%8F%E3%81%97%E3%82%83%E3%81%BF>

=cut
