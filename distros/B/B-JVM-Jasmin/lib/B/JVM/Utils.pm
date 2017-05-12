# Utils.pm                                                        -*- Perl -*-
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.

package B::JVM::Utils;


use 5.000562;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

=head1 NAME

B::JVM::Utils -  Utility functions for B::JVM 

=head1 SYNOPSIS

  use B::JVM::Utils qw(method1 method2);

=head1 DESCRIPTION

This package is a set of utilties that are useful when compiling Perl to the
JVM architecture.  They are a hodgepodge of utilties that don't really fit
anywhere else.

=head1 AUTHOR

Bradley M. Kuhn, bkuhn@ebb.org, http://www.ebb.org/bkuhn

=head1 COPYRIGHT

Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.

=head1 LICENSE

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the LICENSE file that was shipped
with this distribution.

=head1 SEE ALSO

perl(1), B::JVM::Jasmin(3), B::JVM::Emit(3).

=head1 DETAILED DOCUMENTATION

=head2 B::JVM::Jasmin::Utils Package Variables

=over

=item $VERSION

Version number of B::JVM::Utils.  For now, it should always match the version
of B::JVM::Jasmin

=item @EXPORT_OK

All the methods that one can grab from B::JVM::Utils.

=item @EXPORT

We don't export anything by default.

=back

=cut

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw(ExtractMethodData IsValidMethodString IsValidTypeIdentifier);

$VERSION = "0.02";

###############################################################################

=head2 Modules used by B::JVM::Utils

=over

=item Carp

Used for error reporting

=back

=cut

use Carp;

###############################################################################

=head2 Methods in B::JVM::Utils

=over

=cut

#-----------------------------------------------------------------------------

=item B::JVM::ExtractMethodData

usage: B::JVM::ExtractMethodData(METHOD_STRING)

Takes a string that is believed to a valid method string for a JVM method, and
if it is a valid method string, returns a hash reference that looks like:
  { methodName => NAME_OF_THE_METHOD,
    returnType => TYPE_ID_OF_RETURN_TYPE,
    argumentTypes => [ ARGUMENT_1_RETURN_TYPE_ID,
                       ARGUMENT_1_RETURN_TYPE_ID,
                       ... ] }
An undefined value is returned if the method string is not valid.

=cut

sub ExtractMethodData {
  my($methodString) = @_;

  # first, check for the name itself
  my ($methodName, $types, $returnType) =
    ($methodString =~
     m{^(\w+(?:/[\w<>]+)*)                     # the method name
                     \((                       # paren starts list of arg types
                       (?:\[*                  # [ starts an array
                           (?:[BCDFIJSZ]|      # the native java types
                              L\w+(?:/\w+)*;)  # a Java class type
                        )*)\)                  # paren, end of arg types
                     ([BCDFIJSZV]|             # the return type, note that
                        L\w+(?:/\w+)*;)        # V (void) is inculed
         $}x);

  return undef if (not defined($methodName) and not defined($returnType));

  my @types  = ($types  =~
                m{\G(\[*                   # [ starts an array
                  (?:[BCDFIJSZ]|           # the native java types
                     L\w+(?:/\w+)*;))}gx); # a Java class type


  return { methodName    => $methodName,
           returnType    => $returnType,
           argumentTypes => \@types };
}
#-----------------------------------------------------------------------------

=item B::JVM::Utils::IsValidMethodString

usage: B::JVM::Utils::IsValidMethodString(METHOD_STRING)

Takes a string that is believed to a valid method name for a JVM method, and
returns a true iff. the METHOD_STRING is a valid JVM method name

=cut

sub IsValidMethodString {
  return (defined ExtractMethodData($_[0]));
}
#-----------------------------------------------------------------------------

=item B::JVM::Utils

usage: B::JVM::Utils:IsValidTypeIdentifier(TYPE_ID)

Takes a string that is believed to a valid type identifitier name on the
JVM, and returns a true iff. the TYPE_ID is a valid JVM type identifier

=cut

sub IsValidTypeIdentifier {
  return ($_[0] =~ m{^\[*                       # [ starts an array
                        (?:[BCDFIJSZ]|          # the native java types
                              L?\w+(?:/\w+)*;?) # a Java class type
                    }x);
}
#-----------------------------------------------------------------------------

=back

=cut
###############################################################################
1;
__END__

