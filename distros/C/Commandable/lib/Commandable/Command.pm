#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Commandable::Command 0.10;

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
   $args{options}   //= {};
   bless [ @args{qw( name description arguments options package code )} ], $class;
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
sub options     { %{ shift->[3] } }
sub package     { shift->[4] }
sub code        { shift->[5] }

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

   if( my %optspec = $self->options ) {
      push @args, my $opts = {};
      my @remaining;

      while( defined( my $token = $cinv->pull_token ) ) {
         last if $token eq "--";

         my $spec;
         my $value_in_token;

         my $value = 1;
         if( $token =~ s/^--([^=]+)(=|$)// ) {
            my ( $opt, $equal ) = ($1, $2);
            if( !$optspec{$opt} and $opt =~ /no-(.+)/ ) {
               $spec = $optspec{$1} and $spec->negatable
                  or die "Unrecognised option name --$opt\n";
               $value = undef;
            }
            else {
               $spec = $optspec{$opt} or die "Unrecognised option name --$opt\n";
               $value_in_token = length $equal;
            }
         }
         elsif( $token =~ s/^-(.)// ) {
            $spec = $optspec{$1} or die "Unrecognised option name -$1\n";
            $value_in_token = length $token;
         }
         else {
            push @remaining, $token;
            next;
         }

         my $name = $spec->name;

         if( $spec->mode =~ /value$/ ) {
            $value = $value_in_token ? $token
                                     : ( $cinv->pull_token // die "Expected value for option --".$spec->name."\n" );
         }

         if( $spec->mode eq "multi_value" ) {
            push @{ $opts->{$name} }, $value;
         }
         elsif( $spec->mode eq "inc" ) {
            $opts->{$name}++;
         }
         else {
            $opts->{$name} = $value;
         }
      }

      $cinv->putback_tokens( @remaining );

      foreach my $spec ( values %optspec ) {
         my $name = $spec->name;
         $opts->{$name} = $spec->default if defined $spec->default and !exists $opts->{$name};
      }
   }

   foreach my $argspec ( $self->arguments ) {
      my $val = $cinv->pull_token;
      if( defined $val ) {
         if( $argspec->slurpy ) {
            my @vals = ( $val );
            while( defined( $val = $cinv->pull_token ) ) {
               push @vals, $val;
            }
            $val = \@vals;
         }
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
   bless [ @args{qw( name description optional slurpy )} ], $class;
}

sub name        { shift->[0] }
sub description { shift->[1] }
sub optional    { shift->[2] }
sub slurpy      { shift->[3] }

package # hide
   Commandable::Command::_Option;

sub new
{
   my $class = shift;
   my %args = @_;
   warn "Use of $args{name} in a Commandable command option name; should be " . $args{name} =~ s/:$/=/r
      if $args{name} =~ m/:$/;
   $args{mode} = "value" if $args{name} =~ s/[=:]$//;
   $args{mode} = "multi_value" if $args{multi};
   my @names = split m/\|/, delete $args{name};
   $args{mode} //= "set";
   $args{negatable} //= 1 if $args{mode} eq "bool";
   bless [ \@names, @args{qw( description mode default negatable )} ], $class;
}

sub name        { shift->[0]->[0] }
sub names       { @{ shift->[0] } }
sub description { shift->[1] }
sub mode        { shift->[2] }
sub default     { shift->[3] }
sub negatable   { shift->[4] }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
