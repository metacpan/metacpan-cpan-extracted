#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Commandable::Finder::SubAttributes::Attrs 0.07;

use v5.14;
use warnings;

use Carp;

use Attribute::Storage;

sub import_into
{
   my $pkg = shift;
   my ( $caller ) = @_;

   # Importing these lexically is a bit of a mess.
   no strict 'refs';
   *{"${caller}::MODIFY_CODE_ATTRIBUTES"} = \&MODIFY_CODE_ATTRIBUTES;
   push @{"${caller}::ISA"}, __PACKAGE__;
}

sub Command_description :ATTR(CODE)
{
   my $class = shift;
   my ( $text ) = @_;
   return $text;
}

sub Command_arg :ATTR(CODE,MULTI)
{
   my $class = shift;
   my ( $args, $name, $description ) = @_;

   my $optional = $name =~ s/\?$//;

   my %arg = (
      name        => $name,
      description => $description,
      optional    => $optional,
      # TODO: all sorts involving type, eatall, etc...
   );

   push @$args, \%arg;

   return $args;
}

sub Command_opt :ATTR(CODE,MULTI)
{
   my $class = shift;
   my ( $opts, $name, $description, $default ) = @_;

   my $mode = "set";
   $mode = "value" if $name =~ s/:$//;

   my %optspec = (
      name        => $name,
      description => $description,
      mode        => $mode,
      default     => $default,
   );

   push @$opts, \%optspec;

   return $opts;
}

0x55AA;
