
$VERSION = '0.01.02';

use Class::Maker::Examples::Array;
use Class::Maker::Examples::Auth;
use Class::Maker::Examples::Expirable;
use Class::Maker::Examples::Human;
use Class::Maker::Examples::Lockable;
use Class::Maker::Examples::Obsessor;
use Class::Maker::Examples::Commerce;
use Class::Maker::Examples::Trustee;

1;

__END__

=head1 NAME

Class::Maker::Examples - example classes made with Class::Maker

=head1 SYNOPSIS

  use Class::Maker::Examples;

=head1 DESCRIPTION

This is an "example-pack" for Class::Maker. It contains a library of classes, which are more or less
usable (more informative, then functional). I strongly encourage to read the source instead
expecting too much from the documentation.

=head1 INGREDIENTS

=head2 Array - Complete object-oriented array class.

=head2 Auth - Class of authentication.

=head2 Commerce - Rudimentary shopping cart system.

=head2 Expirable - Class for exirable objects.

=head2 Human - Classes representing Humans (Groups/Roles).

=head2 Lockable - Classes for locking mechanisms

=head2 Soccer - Classes for a Soccer Betting Agency [german documentation only]

=head2 Obsessor - Obsesses other objects and functions as a methodcall dispatcher/forwarder

=head2 Trustee - An simple storage specialized on financial objects

=head1 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, muenalan@cpan.org

=head1 SEE ALSO

L<Class::Maker>

=cut
