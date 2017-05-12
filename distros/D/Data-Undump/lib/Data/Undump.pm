package Data::Undump;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( undump );
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );
our @EXPORT = qw(undump);

our $VERSION = '0.15';

require XSLoader;
XSLoader::load('Data::Undump', $VERSION);

1;
__END__

=head1 NAME

Data::Undump - Perl extension for securely and quickly deserializing simple Data::Dumper dumps

=head1 SYNOPSIS

  use Data::Undump qw(undump);
  
  my $dump= Data::Dumper->new([$simple_thing])->Terse(1)->Dump();
  undump($dump);

=head1 DESCRIPTION

Securely and quickly deserialize simple Data::Dumper dumps.

B<Note that this is an early release. Please contact the author(s) if you intend to
use this software in production.>

=head2 EXPORT

By default exports the C<undump> subroutine.

=head1 FUNCTIONS

=head2 undump

Undumps a Data::Dumper style data structure.
Takes a plain string (magic not currently respected)
containing a Data::Dumper Terse/Deepcopy style C<Dumper> output
(ie. no C<$VAR1 => at the front allowed currently) and returns
either undef for a failed parse, or a scalar value of the
value parsed. Also, in case of a failed parse, an error message
will be available in the C<$@> variable.

Restricted to objects nested up to 100 items deep.

=head1 POTENTIAL ENHANCEMENTS

Support for the following isn't implemented but might be in
future enhancements.

 * String magic on input scalar
 * qr//
 * ref to object. Eg \['foo']
 * Make it possible to parse a list instead of a scalar.
 * Blessed objects?
 * Cyclic structures?
 * Less/more tolerant parsing rules?
 * Filters? (Block things by their position in the structure?)
 * Conversion? (IE, we have '[1,1,1]' in the input, and we know we wont
 *    need it so parse it as '1,1,1' instead.

=head1 SEE ALSO

L<Data::Dumper>, L<eval>

=head1 AUTHOR

Yves Orton E<lt>demerphq@gmail.comE<gt>

with contributions by:

Steffen Mueller E<lt>smueller@cpan.orgE<gt>
Rafael Garcia-Suarez E<lt>rgs@consttype.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Yves Orton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

A git repository for this distribution can be found at
L<https://github.com/demerphq/Data-Undump>.

=cut
