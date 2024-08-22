#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

package Commandable::Command 0.12;

use v5.26;
use warnings;
use experimental qw( signatures );

=head1 NAME

C<Commandable::Command> - represent metadata for an invokable command

=head1 DESCRIPTION

Objects in this class are returned by a L<Commandable::Finder> instance to
represent individual commands that exist.

=cut

sub new ( $class, %args )
{
   $args{arguments} //= [];
   $args{options}   //= {};
   bless [ @args{qw( name description arguments options package code )} ], $class;
}

=head1 ACCESSORS

The following simple methods return metadata fields about the command

=cut

=head2 name

=head2 description

   $name = $command->name;
   $desc = $command->description;

Strings giving the short name (to be used on a commandline), and descriptive
text for the command.

=head2 arguments

   @args = $command->arguments;

A (possibly-empty) list of argument metadata structures.

=head2 options

   %opts = $command->options;

A (possibly-empty) kvlist of option metadata structures.

=head2 package

   $pkg = $command->package;

The package name as a plain string.

=head2 code

   $sub = $command->code;

A CODE reference to the code actually implementing the command.

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

I<Since version 0.12> this method has been moved to L<Commandable::Finder>.

=cut

package # hide
   Commandable::Command::_Argument;

=head1 ARGUMENT SPECIFICATIONS

Each argument specification is given by an object having the following structure:

=head2 name

=head2 description

   $name = $argspec->name;

   $desc = $argspec->description;

Text strings for the user, used to generate the help text.

=head2 optional

   $bool = $argspec->optional;

If false, the option is mandatory and an error is raised if no value is
provided for it. If true, it is optional and if absent an C<undef> will passed
instead.

=head2 slurpy

   $bool = $argspec->slurpy;

If true, the argument will be passed as an ARRAY reference containing the
entire remaining list of tokens provided by the user.

=cut

sub new ( $class, %args )
{
   bless [ @args{qw( name description optional slurpy )} ], $class;
}

sub name        { shift->[0] }
sub description { shift->[1] }
sub optional    { shift->[2] }
sub slurpy      { shift->[3] }

package # hide
   Commandable::Command::_Option;

=head1 OPTION SPECIFICATIONS

Each option specification is given by an object having the following
structure:

=head2 name

   $name = $optspec->name;

A string giving the name of the option. This is the name it will be given in
the options hash provided to the command subroutine.

=head2 names

   @names = $optspec->names;

A list containing the name plus all the aliases this option is known by.

=head2 description

   $desc = $optspec->description;

A text string containing information for the user, used to generate the help
text.

=head2 mode

   $mode = $optspec->mode;

A string that describes the behaviour of the option.

C<set> options do not expect a value to be suppled by the user, and will store a
true value in the options hash if present.

C<value> options take a value from the rest of the token, or the next token.

   --opt=value
   --opt value

C<multi_value> options can be supplied more than once; values are pushed into
an ARRAY reference which is passed in the options hash.

C<inc> options may be supplied more than once; each occurance will increment
the stored value by one.

=head2 default

   $val = $optspec->default;

A value to provide in the options hash if the user did not specify a different
one.

=head2 negatable

   $bool = $optspec->negatable;

If true, also accept a C<--no-OPT> option to reset the value of the option to
C<undef>.

=head2 typespec

   $type = $optspec->typespec;

If defined, gives a type specification that any user-supplied value must
conform to.

The C<i> type must be a string giving a (possibly-negative) decimal integer.

=cut

sub new ( $class, %args )
{
   warn "Use of $args{name} in a Commandable command option name; should be " . $args{name} =~ s/:$/=/r
      if $args{name} =~ m/:$/;
   $args{typespec} = $2 if $args{name} =~ s/([=:])(.+?)$/$1/;
   if( defined( my $typespec = $args{typespec} ) ) {
      $typespec eq "i" or
         die "Unrecognised typespec $typespec";
   }
   $args{mode} = "value" if $args{name} =~ s/[=:]$//;
   $args{mode} = "multi_value" if $args{multi};
   my @names = split m/\|/, delete $args{name};
   $args{mode} //= "set";
   $args{negatable} //= 1 if $args{mode} eq "bool";
   bless [ \@names, @args{qw( description mode default negatable typespec )} ], $class;
}

sub name        { shift->[0]->[0] }
sub names       { @{ shift->[0] } }
sub description { shift->[1] }
sub mode        { shift->[2] }
sub default     { shift->[3] }
sub negatable   { shift->[4] }
sub typespec    { shift->[5] }

sub mode_expects_value { shift->mode =~ m/value$/ }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
