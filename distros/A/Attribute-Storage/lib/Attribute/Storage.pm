#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2024 -- leonerd@leonerd.org.uk

package Attribute::Storage 0.12;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

use B qw( svref_2object );

use meta 0.006;  # ->list_symbols
no warnings 'meta::experimental';

=head1 NAME

C<Attribute::Storage> - declare and retrieve named attributes data

=head1 SYNOPSIS

=for highlighter language=perl

   package My::Package;

   use Attribute::Storage;

   sub Title :ATTR(CODE)
   {
      my $package = shift;
      my ( $title ) = @_;

      return $title;
   }

   package main;

   use Attribute::Storage qw( get_subattr );
   use My::Package;

   sub myfunc :Title('The title of my function')
   {
      ...
   }

   print "Title of myfunc is: ".get_subattr(\&myfunc, 'Title')."\n";

=head1 DESCRIPTION

This package provides a base, where a package using it can define handlers for
particular named attributes. Other packages, using the package that defines
the attributes, can then use them to annotate subroutines or variables.

This is similar to C<Attribute::Handlers>, with the following key differences:

=over 4

=item *

C<Attribute::Storage> will store the value returned by the attribute handling
code, and provides convenient lookup functions to retrieve it later.
C<Attribute::Handlers> simply invokes the handling code.

=item *

C<Attribute::Storage> immediately executes the attribute handling code at
compile-time. C<Attribute::Handlers> defers invocation so it can look up the
symbolic name of the sub the attribute is attached to. C<Attribute::Storage>
uses L<B> to provide the name of the sub at invocation time, using the name of
the underlying C<GV>.

=item * 

C<Attribute::Storage> works just as well on anonymous subs as named ones.

=item *

C<Attribute::Storage> is safe to use on code that will be reloaded, because it
executes handlers immediately. C<Attribute::Handlers> will only execute
handlers at defined phases such as C<BEGIN> or C<INIT>, and cannot reexecute
the handlers in a file once it has been reloaded.

=back

I<Since version 0.11> this module also supports attributes on scalar, array
and hash variables.

=cut

sub import
{
   my $class = shift;
   return unless $class eq __PACKAGE__;

   # TODO
   #Attribute::Lexical->import( 'CODE:ATTR' => \&handle_attr_ATTR );

   my $caller = caller;
   my $metacaller = meta::get_package( $caller );

   my $sub = sub {
      my ( $pkg, $ref, @attrs ) = @_;
      grep {
         my ( $attrname, $opts ) = m/^([A-Za-z_][0-9A-Za-z_]*)(?:\((.*)\))?$/s;
         defined $opts or $opts = "";
         $attrname eq "ATTR" ?
            handle_attr_ATTR( $pkg, $ref, $attrname, $opts ) :
            handle_attr     ( $pkg, $ref, $attrname, $opts );
      } @attrs;
   };

   $metacaller->add_symbol( '&MODIFY_CODE_ATTRIBUTES',   $sub );
   $metacaller->add_symbol( '&MODIFY_SCALAR_ATTRIBUTES', $sub );
   $metacaller->add_symbol( '&MODIFY_ARRAY_ATTRIBUTES',  $sub );
   $metacaller->add_symbol( '&MODIFY_HASH_ATTRIBUTES',   $sub );

   # Some simple Exporter-like logic. Just does function refs
   foreach my $symb ( @_ ) {
      $sub = __PACKAGE__->can( $symb ) or croak __PACKAGE__." has no function '$symb'";
      $metacaller->add_symbol( '&'.$symb, $sub );
   }
}

=head1 ATTRIBUTES

Each attribute that the defining package wants to define should be done using
a marked subroutine, in a way similar to L<Attribute::Handlers>. When a sub in
the using package is marked with such an attribute, the code is executed,
passing in the arguments. Whatever it returns is stored, to be returned later
when queried by C<get_subattr> or C<get_subattrs>. The return value must be
defined, or else the attribute will be marked as a compile error for perl to
handle accordingly.

   sub AttributeName :ATTR(CODE)
   {
      my $package = shift;
      my ( $attr, $args, $here ) = @_;
      ...
      return $value;
   }

At attachment time, the optional string that may appear within brackets
following the attribute's name is parsed as a Perl expression in list context.
If this succeeds, the values are passed as a list to the handling code. If
this fails, an error is returned to the perl compiler. If no string is
present, then an empty list is passed to the handling code.

   package Defining;

   sub NameMap :ATTR(CODE)
   {
      my $package = shift;
      my @strings = @_;

      return { map { m/^(.*)=(.*)$/ and ( $1, $2 ) } @strings };
   }

   package Using;

   use Defining;

   sub somefunc :NameMap("foo=FOO","bar=BAR","splot=WIBBLE") { ... }

   my $map = get_subattr("somefunc", "NameMap");
   # Will yield:
   #  { foo   => "FOO",
   #    bar   => "BAR",
   #    splot => "WIBBLE" }

Note that it is impossible to distinguish

   sub somefunc :NameMap   { ... }
   sub somefunc :NameMap() { ... }

It is possible to create attributes that do not parse their argument as a perl
list expression, instead they just pass the plain string as a single argument.
For this, add the C<RAWDATA> flag to the C<ATTR()> list.

   sub Title :ATTR(CODE,RAWDATA)
   {
      my $package = shift;
      my ( $text ) = @_;

      return $text;
   }

   sub thingy :Title(Here is the title for thingy) { ... }

To obtain the name of the function to which the attribute is being applied,
use the C<NAME> flag to the C<ATTR()> list.

   sub Callable :ATTR(CODE,NAME)
   {
      my $package = shift;
      my ( $subname, @args ) = @_;

      print "The Callable attribute is being applied to $package :: $subname\n";

      return;
   }

Only C<CODE> attributes support the C<NAME> flag; it cannot be applied when
C<SCALAR>, C<ARRAY> or C<HASH> are also present.

When applied to an anonymous function (C<sub { ... }>), the name will appear
as C<__ANON__>.

Normally it is an error to attempt to apply the same attribute more than once
to the same target. Sometimes however, it would make sense for an attribute
to be applied many times. If the C<ATTR()> list is given the C<MULTI> flag,
then applying it more than once will be allowed. Each invocation of the
handling code will be given the previous value that was returned, or C<undef>
for the first time. It is up to the code to perform whatever merging logic is
required.

   sub Description :ATTR(CODE,MULTI,RAWDATA)
   {
      my $package = shift;
      my ( $olddesc, $more ) = @_;

      return defined $olddesc ? "$olddesc$more\n" : "$more\n";
   }

   sub Argument :ATTR(CODE,MULTI)
   {
      my $package = shift;
      my ( $args, $argname ) = @_;

      push @$args, $argname;
      return $args;
   }

   sub Option :ATTR(CODE,MULTI)
   {
      my $package = shift;
      my ( $opts, $optname ) = @_;

      $opts and exists $opts->{$optname} and
         croak "Already have the $optname option";

      $opts->{$optname}++;
      return $opts;
   }

   ...

   sub do_copy
      :Description(Copy from SOURCE to DESTINATION)
      :Description(Optionally preserves attributes)
      :Argument("SOURCE")
      :Argument("DESTINATION")
      :Option("attrs")
      :Option("verbose")
   {
      ...
   }

=cut

sub handle_attr_ATTR
{
   my ( $pkg, $ref, undef, $opts ) = @_;

   my $attrs = _get_attr_hash( $ref, 1 );

   my %type;
   foreach ( split m/\s*,\s*/, $opts ) {
      m/^(?:CODE|SCALAR|ARRAY|HASH)$/ and 
         ( $type{lc $_} = 1 ), next;

      m/^RAWDATA$/ and
         ( $type{raw} = 1 ), next;

      m/^MULTI$/ and
         ( $type{multi} = 1 ), next;

      m/^NAME$/ and
         ( $type{name} = 1 ), next;

      croak "Unrecognised attribute option $_";
   }

   if( $type{name} ) {
      # TODO: maybe this could be made to work but it seems to require a lot
      # of hunting around in the symbol table or lexical pad to work out the
      # name when given only a reference. Probably not worth it?
      $type{lc $_} and croak "Cannot apply NAME to :ATTR($_)" for qw( SCALAR ARRAY HASH );
   }

   $attrs->{ATTR} = \%type;

   return 0;
}

sub handle_attr
{
   my ( $pkg, $ref, $attrname, $opts ) = @_;

   my $cv = $pkg->can( $attrname ) or return 1;
   my $cvattrs = _get_attr_hash( $cv, 0 ) or return 1;
   my $type = $cvattrs->{ATTR} or return 1;

   my $reftype = ref $ref;

   $reftype =~ m/^(?:CODE|SCALAR|ARRAY|HASH)$/ && $type->{lc $reftype} or
      croak "Cannot apply :$attrname to $reftype reference";

   my @opts;
   if( $type->{raw} ) {
      @opts = ( $opts );
   }
   else {
      @opts = do {
         no strict;
         defined $opts ? eval $opts : ();
      };

      if( $@ ) {
         my ( $msg ) = $@ =~ m/^(.*) at \(eval \d+\) line \d+\.$/;
         croak "Unable to parse $attrname - $msg";
      }
   }

   my $attrs = _get_attr_hash( $ref, 1 );

   if( $type->{name} ) {
      unshift @opts, svref_2object( $ref )->GV->NAME;
   }

   if( $type->{multi} ) {
      unshift @opts, $attrs->{$attrname};
   }
   else {
      exists $attrs->{$attrname} and 
         croak "Already have the $attrname attribute";
   }

   my $value = eval { $cv->( $pkg, @opts ) };
   die $@ if $@;
   defined $value or return 1;

   $attrs->{$attrname} = $value;

   return 0;
}

=head1 FUNCTIONS

=cut

=head2 get_subattrs

   $attrs = get_subattrs( $sub );

Returns a HASH reference containing all the attributes defined on the given
sub. The sub should either be passed as a CODE reference, or as a name in the
caller's package.

=head2 get_varattrs

   $attrs = get_varattrs( $varref );

I<Since version 0.11.>

Returns a HASH reference containing all the attributes defined on the given
variable, which should be passed in by reference.

In both of the above functions, the returned HASH reference is a new shallow
clone, and the caller may modify this hash arbitrarily without breaking the
stored data or other users of it. If no attributes are defined then a
reference to an empty HASH is returned.

=cut

sub get_subattrs
{
   my ( $sub ) = @_;

   defined $sub or croak "Need a sub";

   my $cv;
   if( ref $sub ) {
      $cv = $sub;
   }
   else {
      my $caller = caller;
      $cv = $caller->can( $sub );
      defined $cv or croak "$caller has no sub $sub";
   }

   my $attrhash = _get_attr_hash( $cv, 0 ) or return {};
   return { %$attrhash };
}

sub get_varattrs
{
   my ( $varref ) = @_;

   my $attrhash = _get_attr_hash( $varref, 0 ) or return {};
   return { %$attrhash };
}

=head2 get_subattr

   $value = get_subattr( $sub, $attrname );

Returns the value of a single named attribute on the given sub. The sub should
either be passed as a CODE reference, or as a name in the caller's package.

=head2 get_varattr

   $value = get_varattr( $varref, $attrname );

I<Since version 0.11.>

Returns the value of a single named attribute on the given variable, which
should be passed in by reference.

In both of the above functions, if the attribute is not defined then C<undef>
is returned.

=cut

sub get_subattr
{
   my ( $sub, $attr ) = @_;

   defined $sub or croak "Need a sub";

   my $cv;
   if( ref $sub ) {
      $cv = $sub;
   }
   else {
      my $caller = caller;
      $cv = $caller->can( $sub );
      defined $cv or croak "$caller has no sub $sub";
   }

   my $attrhash = _get_attr_hash( $cv, 0 ) or return undef;
   return $attrhash->{$attr};
}

sub get_varattr
{
   my ( $varref, $attr ) = @_;

   my $attrhash = _get_attr_hash( $varref, 0 ) or return undef;
   return $attrhash->{$attr};
}

=head2 apply_subattrs

   $sub = apply_subattrs( @attrs_kvlist, $sub );

A utility function to help apply attributes dynamically to the given CODE
reference. The CODE reference is given last so that calls to the function
appear similar in visual style to the same applied at compiletime.

   apply_subattrs
      Title => "Here is my title",
      sub { return $title };

Is equivalent to

   sub :Title(Here is my title) { return $title }

except that because its arguments are evaluated at runtime, they can be
calculated by other code in ways that the compiletime version cannot.

As the attributes are given in a key-value pair list, it is allowed to apply
the same attribute multiple times; and the attributes are applied in the order
given. The value of each attribute should be a plain string exactly as it
would appear between the parentheses. Specifically, if the attribute does not
use the C<RAWDATA> flag, it should be a valid perl expression. As this is
still evaluated using an C<eval()> call, take care when handling
potentially-unsafe or user-supplied data.

=head2 apply_subattrs_for_pkg

   $sub = apply_subattrs_for_pkg( $pkg, @attrs_kvlist, $sub );

As C<apply_subattrs> but allows passing a specific package name, rather than
using C<caller>.

=cut

sub apply_subattrs_for_pkg
{
   my $pkg = shift;
   my $sub = pop;

   while( @_ ) {
      my $attr = shift;
      my $value = shift;
      attributes->import( $pkg, $sub, "$attr($value)" );
   }

   return $sub;
}

sub apply_subattrs
{
   apply_subattrs_for_pkg( scalar caller, @_ );
}

=head2 find_subs_with_attr

   %subs = find_subs_with_attr( $pkg, $attrname, %opts );

A utility function to find CODE references in the given package that have the
named attribute applied. The symbol table is checked for the given package,
looking for CODE references that have the named attribute applied. These are
returned in a key-value list, where the key gives the name of the function and
the value is a CODE reference to it.

C<$pkg> can also be a reference to an array containing multiple package names,
which will be searched in order with earlier ones taking precedence over later
ones. This, for example, allows for subclass searching over an entire class
heirarchy of packages, via the use of L<mro>:

   %subs = find_subs_with_attr( mro::get_linear_isa( $class ), $attrname );

=head2 find_vars_with_attr

   %vars = find_vars_with_attr( $pkg, $attrname, %opts );

I<Since version 0.11.>

A utility function to find SCALAR, ARRAY or HASH references in the given
package that have the named attribute applied. The symbol table is checked for
the given package, looking for variable references that have the named
attribute applied. These are returned in a key-value list, where the key gives
the name of the variable and the value is a reference to it.

Unlike for L</find_subs_with_attr>, the C<$pkg> argument must be a single
package name; no subclass search takes place.

Both of the above functions take the following named options:

=over 8

=item matching => Regexp | CODE

If present, gives a filter regexp or CODE reference to apply to names. Subs
will be given as plain names; variable names will include the leading sigil.

   $name =~ $matching;
   $matching->( local $_ = $name );

=item filter => CODE

If present, gives a filter CODE reference to apply to the target references
before they are accepted as results. Note that this allows the possibility
that the first match for a given method name to be rejected, while later ones
are accepted.

   $filter->( $ref, $name, $package );

=back

=cut

sub find_subs_with_attr
{
   my ( $pkg, $attrname, %opts ) = @_;

   my $matching = $opts{matching};
   $matching = do {
      my $re = $matching;
      sub { $_ =~ $re }
   } if ref $matching eq "Regexp";

   my $filter = $opts{filter};

   my %ret;

   foreach $pkg ( ref $pkg ? @$pkg : $pkg ) {
      my $metapkg = meta::get_package( $pkg );

      # If we were on perl 5.36+ we could use multivariable foreach
      my %metasyms = $metapkg->list_symbols( sigils => '&' );
      foreach ( keys %metasyms ) {
         my $metasym = $metasyms{$_};
         my $symname = $_ =~ s/^&//r;
         my $cv = $metasym->reference;

         # First definition wins
         exists $ret{$symname} and next;

         $matching and not $matching->( local $_ = $symname ) and next;

         next unless defined get_subattr( $cv, $attrname );

         $filter and not $filter->( $cv, $symname, $pkg ) and next;

         $ret{$symname} = $cv;
      }
   }

   return %ret;
}

sub find_vars_with_attr
{
   my ( $pkg, $attrname, %opts ) = @_;

   my $matching = $opts{matching};
   $matching = do {
      my $re = $matching;
      sub { $_ =~ $re }
   } if ref $matching eq "Regexp";

   my $filter = $opts{filter};

   my %ret;

   {
      my $metapkg = meta::get_package( $pkg );

      # If we were on perl 5.36+ we could use multivariable foreach
      my %metasyms = $metapkg->list_symbols( sigils => '$@%' );
      foreach my $varname ( keys %metasyms ) {
         my $metasym = $metasyms{$varname};
         my $varref  = $metasym->reference;

         $matching and not $matching->( local $_ = $varname ) and next;

         next unless defined get_varattr( $varref, $attrname );

         $filter and not $filter->( $varref, $varname, $pkg ) and next;

         $ret{$varname} = $varref;
      }
   }

   return %ret;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
