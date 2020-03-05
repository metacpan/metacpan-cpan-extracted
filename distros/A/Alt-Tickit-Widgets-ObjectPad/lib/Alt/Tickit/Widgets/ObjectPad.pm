package Alt::Tickit::Widgets::ObjectPad;

our $VERSION = '0.29';

=head1 NAME

C<Alt::Tickit::Widgets::ObjectPad> - an alternative implemention of L<Tickit::Widgets> based on L<Object::Pad>

=head1 DESCRIPTION

This distribution provides an alternative implementation of L<Tickit::Widgets>
whose classes are built using L<Object::Pad>, rather than basic perl OO. Its
functionallity is intended to be identical to the primary distribution. It
exists simply to demonstrate the use of C<Object::Pad> in nontrivial code
examples, and to help smoke test the module being used.

=head1 INSTALLATION

For safety purposes, by default this module installs into a local directory
rather than overwriting the primary installation path. If you wish to install
this implementation directly over the primary one, set the environment variable
C<PERL_ALT_INSTALL> to the value C<OVERWRITE>.

   $ PERL_ALT_INSTALL=OVERWRITE cpan Alt::Tickit::Widgets::ObjectPad

or

   $ PERL_ALT_INSTALL=OVERWRITE perl Build.PL
   $ ./Build && ./Build install

or other equivalent.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
