#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

package Commandable::Finder::SubAttributes::Attrs 0.12;

use v5.26;
use warnings;
use experimental qw( signatures );

use Carp;
use meta 0.003_003;
no warnings qw( meta::experimental );

use Attribute::Storage;

=head1 NAME

C<Commandable::Finder::SubAttributes::Attrs> - subroutine attribute definitions for C<Commandable::Finder::SubAttributes>

=head1 DESCRIPTION

This module contains the attribute definitions to apply to subroutines when
using L<Commandable::Finder::SubAttributes>. It should not be used directly.

=cut

sub import_into ( $pkg, $caller )
{
   # Importing these lexically is a bit of a mess.
   my $callermeta = meta::package->get( $caller );

   $callermeta->add_symbol( '&MODIFY_CODE_ATTRIBUTES' => \&MODIFY_CODE_ATTRIBUTES );
   push @{ $callermeta->get_or_add_symbol( '@ISA' )->reference }, __PACKAGE__;
}

sub Command_description :ATTR(CODE) ( $class, $text )
{
   return $text;
}

sub Command_arg :ATTR(CODE,MULTI) ( $class, $args, $name, $description )
{
   my $optional = $name =~ s/\?$//;
   my $slurpy   = $name =~ s/\.\.\.$//;

   my %arg = (
      name        => $name,
      description => $description,
      optional    => $optional,
      slurpy      => $slurpy,
      # TODO: all sorts involving type, etc...
   );

   push @$args, \%arg;

   return $args;
}

sub Command_opt :ATTR(CODE,MULTI) ( $class, $opts, $name, $description = undef, $default = undef )
{
   my $mode = "set";
   $mode = "value" if $name =~ s/=$//;
   $mode = "inc"   if $name =~ s/\+$//;

   my $negatable = $name =~ s/\!$//;
   my $multi     = $name =~ s/\@$//;

   my %optspec = (
      name        => $name,
      description => $description,
      mode        => $mode,
      multi       => $multi,
      negatable   => $negatable,
      default     => $default,
   );

   push @$opts, \%optspec;

   return $opts;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
