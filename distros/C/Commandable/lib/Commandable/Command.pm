#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Commandable::Command 0.05;

use v5.14;
use warnings;

=head1 NAME

C<Commandable::Command> - represent metadata for an invokable command

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   $args{arguments} //= [];
   bless [ @args{qw( name description arguments package code )} ], $class;
}

=head1 ACCESSORS

The following simple methods return metadata fields about the command

=cut

=head2 name

=head2 description

   $name = $command->name
   $desc = $command->description

Strings giving the short name (to be used on a commandline), and descriptive
text for the command.

=head2 arguments

   @args = $command->arguments

A (possibly-empty) list of argument metadata structures.

=cut

sub name        { shift->[0] }
sub description { shift->[1] }
sub arguments   { @{ shift->[2] } }
sub package     { shift->[3] }
sub code        { shift->[4] }

=head1 METHODS

=cut

=head2 parse_invocation

   @vals = $command->parse_invocation( $cinv )

Parses values out of a L<Commandable::Invocation> instance according to the
specification for the command's arguments. Returns a list of perl values
suitable to pass into the function implementing the command.

This method will throw an exception if mandatory arguments are missing.

=cut

sub parse_invocation
{
   my $self = shift;
   my ( $cinv ) = @_;

   my @args;

   # TODO: options parsing here

   foreach my $argspec ( $self->arguments ) {
      my $val = $cinv->pull_token;
      if( defined $val ) {
         push @args, $val;
      }
      elsif( !$argspec->optional ) {
         die "Expected a value for '".$argspec->name."' argument\n";
      }
      else {
         # optional argument was missing; this is the end of the args
         last;
      }
   }

   return @args;
}

package # hide
   Commandable::Command::_Argument;

sub new
{
   my $class = shift;
   my %args = @_;
   bless [ @args{qw( name description optional )} ], $class;
}

sub name        { shift->[0] }
sub description { shift->[1] }
sub optional    { shift->[2] }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
