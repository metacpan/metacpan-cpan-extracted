#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Commandable::Command 0.11;

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
   $args{config}    //= {};
   bless [ @args{qw( name description arguments options package code config )} ], $class;
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

   $pkg = $command->packaage;

The package name as a plain string.

=head2 code

   $sub = $command->code;

A CODE reference to the code actually implementing the command.

=head2 config

   $conf = $command->config;

A HASH reference to the configuration of the command.

=cut

sub name        { shift->[0] }
sub description { shift->[1] }
sub arguments   { @{ shift->[2] } }
sub options     { %{ shift->[3] } }
sub package     { shift->[4] }
sub code        { shift->[5] }
sub config      { shift->[6] }

=head1 METHODS

=cut

=head2 parse_invocation

   @vals = $command->parse_invocation( $cinv );

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
         my $token_again;

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
            if( $spec->mode_expects_value ) {
               $value_in_token = length $token;
            }
            elsif( $self->config->{bundling} and length $token and length($1) == 1 ) {
               $token_again = "-$token";
               undef $token;
            }
         }
         else {
            push @remaining, $token;
            if( $self->config->{require_order} ) {
               last;
            }
            else {
               next;
            }
         }

         my $name = $spec->name;

         if( $spec->mode_expects_value ) {
            $value = $value_in_token ? $token
                                     : ( $cinv->pull_token // die "Expected value for option --$name\n" );
         }
         else {
            die "Unexpected value for parameter $name\n" if $value_in_token or length $token;
         }

         if( defined( my $typespec = $spec->typespec ) ) {
            if( $typespec eq "i" ) {
               $value =~ m/^-?\d+$/ or
                  die "Value for parameter $name must be an integer\n";
            }
         }

         $name =~ s/-/_/g;

         if( $spec->mode eq "multi_value" ) {
            push @{ $opts->{$name} }, $value;
         }
         elsif( $spec->mode eq "inc" ) {
            $opts->{$name}++;
         }
         else {
            $opts->{$name} = $value;
         }

         $token = $token_again, redo if defined $token_again;
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

sub new
{
   my $class = shift;
   my %args = @_;
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
