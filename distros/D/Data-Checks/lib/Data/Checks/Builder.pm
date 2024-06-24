#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Data::Checks::Builder 0.03;

use v5.22;
use warnings;

=head1 NAME

C<Data::Checks::Builder> - build-time support for C<Data::Checks>

=head1 SYNOPSIS

In F<Build.PL>:

   use Data::Checks::Builder;

   my $build = Module::Build->new(
      ...,
      configure_requires => {
         ...
         'Data::Checks::Builder' => 0,
      }
   );

   Data::Checks::Builder->extend_module_build( $build );

   ...

=head1 DESCRIPTION

This module provides a build-time helper to assist authors writing XS modules
that use L<Data::Checks>. It prepares a L<Module::Build>-using
distribution to be able to make use of C<Data::Checks>.

=cut

=head2 extra_compiler_flags

   @flags = Data::Checks::Builder->extra_compiler_flags;

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<DataChecks.h> file.

=cut

sub extra_compiler_flags
{
   shift;

   require File::ShareDir;
   require File::Spec;
   return "-I" . File::Spec->catdir( File::ShareDir::dist_dir( "Data-Checks" ), "include" );
}

=head2 extend_module_build

   Data::Checks::Builder->extend_module_build( $build );

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   # preserve existing flags
   my @flags = @{ $build->extra_compiler_flags };
   push @flags, $self->extra_compiler_flags;

   $build->extra_compiler_flags( @flags );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
