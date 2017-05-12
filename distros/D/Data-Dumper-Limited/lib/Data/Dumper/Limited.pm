package Data::Dumper::Limited;
use 5.008;
use strict;
use warnings;
use Carp qw/croak/;
use XSLoader;

our $VERSION = '0.03';
use Exporter 'import';
our @EXPORT_OK = qw(DumpLimited);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

XSLoader::load('Data::Dumper::Limited', $VERSION);

1;

__END__

=head1 NAME

Data::Dumper::Limited - Vastly faster subset of Data::Dumper functionality

=head1 SYNOPSIS

  use Data::Dumper::Limited qw(DumpLimited);
  print DumpLimited($your_structure);

=head1 DESCRIPTION

B<This is an experimental module. The interface may change without notice.
Before using it in production, please get in touch with the authors!>

Think of C<Data::Dumper::Limited> as supporting a subset of the data structures
and features of L<Data::Dumper>. The output is still valid Perl, so you can
abuse C<eval STRING> for deserialization. Alternatively, you can choose to use
L<Data::Undump>, which is a couple of orders of magnitude faster than eval and
does not have the same security implications. Did we mention that this module
dumps over 10x faster than Data::Dumper (similar to JSON::XS in our benchmarks)?

The power of this module is very similar to that of generating JSON, except it
can dump scalar references, dumps top-level non-references (JSON must be an array
or hash ref on the outside), and, again, is valid Perl. Furthermore, this module
can optionally dump plain Perl object using C<bless()> function calls. Since
this can be unsafe, it needs to be explicitly enabled.

Repeated sub-references are detected, as are cyclic references. Repeated
sub-structures are simply serialized multiple times -- they do not round-trip
as repeated sub-structures. Since that is at least somewhat dubious, you can
set an option that will make C<DumpLimited> throw an exception when encountering
repeated sub-structures. Cyclic references currently always cause the module
to throw an exception as they are not supported.

=head1 EXPORTABLE FUNCTIONS

=head2 DumpLimited($structure, $options)

This function will return a string that represents the serialization of the first
parameter to the function. Optionally, the second parameter can be a hash reference
that contains any one of several options, see below.

Available options (as hash keys in the options hash reference):

=over 2

=item C<undef_blessed>

Boolean, defaults to false.
Instead of dying on blessed references, simply emit C<undef>.

=item C<objects_as_unblessed>

Boolean, defaults to false.
Instead of dying on blessed references, simply serialize them as unblessed
references.

=item C<dump_objects>

Boolean, defaults to false.
Instead of dying on blessed references, serialize them properly including
a call to C<bless()>. Does not include logic for loading thusly referenced
modules. That is by design. In the future, this might accept a list of acceptable
class names to bless into.

=item C<disallow_multi>

Boolean, defaults to false.
If set, the module will refuse to serialize common sub-structures and throw
and exception instead (eg. C<[\$x, \$x]>.

=back

The options C<undef_blessed>, C<objects_as_unblessed>, and C<dump_objects> are
mutually exclusive and trying to set more than one of them will yield an
exception.

=head1 SEE ALSO

The original L<Data::Dumper>.

L<Data::Undump> implements the efficient deserialization for this format (minus objects).

L<JSON::XS> contains some excellent code that is very similar to
the code in this module for a reason: It solves a similar problem and
we included much of the code structure from JSON::XS. Thank you, Marc,
for writing great software.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

Yves Orton E<lt>demerphq@gmail.comE<gt>

Some inspiration and code was taken from Marc Lehmann's
excellent JSON::XS module due to obvious overlap in
problem domain.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013 by Steffen Mueller

Except portions taken from Marc Lehmann's code for the JSON::XS
module. The license for JSON::XS is the same as for this module:

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
