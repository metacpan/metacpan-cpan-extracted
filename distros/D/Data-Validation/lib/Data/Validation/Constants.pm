package Data::Validation::Constants;

use strict;
use warnings;
use parent 'Exporter::Tiny';

use Data::Validation::Exception;

our @EXPORT = qw( EXCEPTION_CLASS FALSE HASH NUL SPC TRUE );

my $Exception_Class = 'Data::Validation::Exception';

sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }
sub FALSE           () { 0      }
sub HASH            () { 'HASH' }
sub NUL             () { q()    }
sub SPC             () { q( )   }
sub TRUE            () { 1      }

sub Exception_Class {
   my ($self, $class) = @_; defined $class or return $Exception_Class;

   $class->can( 'throw' )
      or die "Class '${class}' is not loaded or has no 'throw' method";

   return $Exception_Class = $class;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Data::Validation::Constants - Defines constants used by this distribution

=head1 Synopsis

   use Data::Validation::Constants;

=head1 Description

Defines constants used by this distribution

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<EXCEPTION_CLASS>

Class name used to throw exceptions. Defaults to the value of the class
attribute

=item C<FALSE>

The digit zero

=item C<HASH>

The string C<HASH>

=item C<NUL>

The null string

=item C<SPC>

The space character

=item C<TRUE>

The digit one

=back

=head1 Subroutines/Methods

=head2 Exception_Class

Accessor / mutator for the class attribute

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter::Tiny>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validation.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
