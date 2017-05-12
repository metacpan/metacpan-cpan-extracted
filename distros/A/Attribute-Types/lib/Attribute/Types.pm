package Attribute::Types;
use Attribute::Handlers;
use Carp;

$VERSION = '0.10';

sub FETCH { return ${$_[0]->{accessor}->(@_)} }
sub FETCHSIZE { return @{$_[0]{val}||=[]} }
sub EXISTS    { return exists $_[0]{val}{$_[1]} }

sub tie_any {
	my ($referent, $tieclass, @args) = @_;
	my $type = ref $referent;
	if ($type eq 'SCALAR') { return tie $$referent, $tieclass, @args }
	if ($type eq 'ARRAY')  { return tie @$referent, $tieclass, @args }
	if ($type eq 'HASH')   { return tie %$referent, $tieclass, @args }
	die "Can't specify type attribute for $type\n";
}

sub INTEGER : ATTR(RAWDATA)
	{ tie_any $_[2], 'Attribute::Types::INTEGER', $_[4]||"" }

sub NUMBER : ATTR(RAWDATA)
	{ tie_any $_[2], 'Attribute::Types::NUMBER', $_[4]||"" }

sub SCALAR :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::SCALAR'}
sub ARRAY  :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::ARRAY'}
sub HASH   :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::HASH'}
sub CODE   :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::CODE'}
sub GLOB   :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::GLOB'}
sub REF    :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::REF'}
sub REGEX  :ATTR(RAWDATA) {tie_any $_[2], 'Attribute::Types::Regexp'}

sub Type   :ATTR(RAWDATA) {
	if ($_[4] =~ m{^\s*(([a-z]\w*::)*[a-z]\w*)\s*$}i) 
		{ return tie_any $_[2], 'Attribute::Types::Class', $1 }
	if ($_[4] =~ m{^\s*/([^/\\]*(\\.[^\//]*)*)/\s*$}) 
		{ return tie_any $_[2], 'Attribute::Types::Pattern', $1 }
	if ($_[4] =~ m{^\s*&\s*([a-z]\w*)\s*$}i) 
		{ return tie_any $_[2], 'Attribute::Types::Generic', "$_[0]::$1" }
	if ($_[4] =~ m{^\s*&\s*([a-z]\w*(::[a-z]\w*)*)\s*$}i) 
		{ return tie_any $_[2], 'Attribute::Types::Generic', $1 }
	die "Invalid type specifier: Type($_[4])\n";
}

my %attr = map {($_=>1) }
	       qw{ INTEGER NUMBER SCALAR ARRAY HASH CODE GLOB REF REGEX Type };

sub import {
	my ($class, @exports) = @_;
	@exports = keys %attr unless @exports;
	my @unknown = grep { !$attr{$_} } @exports;
	croak "Unknown type", (@unknown==1?"":"s") ,": @unknown" if @unknown;
	foreach (@exports) {
		next if $attr{$_} > 1;
		no warnings;
		eval qq{ sub UNIVERSAL::$_ :ATTR(RAWDATA) { goto &Attribute::Types::$_} };
		$attr{$_}++;
	}
}


sub verify(&) {
	use warnings 'all';
	local $^W = 1;
	my $fail = 0;
	local $SIG{__WARN__} = sub { $fail=1 };
	return eval { $_[0]->() && !$fail };
}

sub _getscalar { \$_[0]->{val} }

sub TIESCALAR { shift->TIE(@_, \&_getscalar) }
sub TIEARRAY  { shift->TIE(@_, sub { \$_[0]->{val}[$_[1]] }) }
sub TIEHASH   { shift->TIE(@_, sub { \$_[0]->{val}{$_[1]} }) }

sub DESTROY {}

package Attribute::Types::numeric;
use base Attribute::Types;
use Carp;

sub TIE {
	my ($tieclass, $range, $accessor) = @_;
	my ($from)   = $range =~ m/(.+)[.][.]/;
	my ($to)     = $range =~ m/.*[.][.](.+)/;
	$range &&= "($range)";
	my ($name) = $tieclass =~ /.*::(.*)/;
	bless { type => "${name}${range}",
		from => $from, to => $to, accessor => $accessor
	      }, $tieclass;
}

sub STORE {
	my ($self, $idx, $val) = @_;
	my $type = $self->{type};
	$val = $idx if $self->{accessor} eq \&Attribute::Types::_getscalar;
	my $value = defined $val ? $val : '<undef>';
	croak "Cannot assign $value to $type variable"
		unless (!ref($val) && $self->test($val))
		    && (!defined $self->{from}
			|| Attribute::Types::verify { $val>=$self->{from} })
		    && (!defined $self->{to} 
			|| Attribute::Types::verify { $val<=$self->{to} });
	${$self->{accessor}->(@_)} = $val;
}

package Attribute::Types::reference;
use base Attribute::Types;
use Carp;

sub TIE {
	my ($tieclass, $accessor) = @_;
	my ($name) = $tieclass =~ /.*::(.*)/;
	bless { type => $name, accessor => $accessor }, $tieclass;
}

sub STORE {
	my ($self, $idx, $val) = @_;
	my $type = $self->{type};
	$val = $idx if $self->{accessor} eq \&Attribute::Types::_getscalar;
	my $value = defined $val ? $val : '<undef>';
	ref($val) && ref($val)->isa($self->{type})
		or croak "Cannot assign $value to $type variable" ;
	${$self->{accessor}->(@_)} = $val;
}

package Attribute::Types::INTEGER;
use base Attribute::Types::numeric;

sub test { my $n = $_[1]; Attribute::Types::verify { int($n)==$n } }


package Attribute::Types::NUMBER;
use base Attribute::Types::numeric;

sub test { my $n= $_[1]; Attribute::Types::verify { $n+0 eq $n*1 } }


package Attribute::Types::SCALAR; use base Attribute::Types::reference;
package Attribute::Types::ARRAY;  use base Attribute::Types::reference;
package Attribute::Types::HASH;   use base Attribute::Types::reference;
package Attribute::Types::CODE;   use base Attribute::Types::reference;
package Attribute::Types::GLOB;   use base Attribute::Types::reference;
package Attribute::Types::REF;    use base Attribute::Types::reference;
package Attribute::Types::Regexp; use base Attribute::Types::reference;


package Attribute::Types::Class;  use base Attribute::Types::reference;

sub TIE {
	my ($tieclass, $storeclass, $accessor) = @_;
	bless { type => $storeclass, accessor => $accessor }, $tieclass;
}


package Attribute::Types::Pattern; use base Attribute::Types;
use Carp;

sub TIE {
	my ($tieclass, $pattern, $accessor) = @_;
	bless { type => "Type(/$pattern/)", pattern => qr/$pattern/,
		accessor => $accessor }, $tieclass;
}

sub STORE {
	my ($self, $idx, $val) = @_;
	my $type = $self->{type};
	$val = $idx if $self->{accessor} eq \&Attribute::Types::_getscalar;
	my $value = defined $val ? $val : '<undef>';
	defined $val and $val =~ $self->{pattern}
		or croak "Cannot assign $value to $type variable" ;
	${$self->{accessor}->(@_)} = $val;
}


package Attribute::Types::Generic; use base Attribute::Types;
use Carp;

sub TIE {
	no strict 'refs';
	my ($tieclass, $subref, $accessor) = @_;
	die "Can't use undefined subroutine &$subref as a type specifier\n"
		unless *{$subref}{CODE};
	bless { type => "Type(\\&$subref)", test => \&{$subref},
		accessor => $accessor }, $tieclass;
}

sub STORE {
	my ($self, $idx, $val) = @_;
	my $type = $self->{type};
	$val = $idx if $self->{accessor} eq \&Attribute::Types::_getscalar;
	my $value = defined $val ? $val : '<undef>';
	$self->{test}->($val)
		or croak "Cannot assign $value to $type variable" ;
	${$self->{accessor}->(@_)} = $val;
}

1;
__END__

=head1 NAME

Attribute::Types - Attributes that confer type on variables

=head1 VERSION

This document describes version 0.10 of Attribute::Types,
released May 10, 2001.

=head1 SYNOPSIS

    use Attribute::Types;

    my $count   : INTEGER;	     # Can only store an integer
    my $date    : INTEGER(1..31);    # Can only store an int between 1..31
    my $value   : NUMBER;	     # Can only store a number
    my $score   : NUMBER(0.1..9.9);  # Can only store a num between 0.1..9.9
    my @rain    : NUMBER;	     # Elements can only store numbers
    my %vars    : SCALAR;	     # Entries can only store scalar refs
    my %handler : CODE;		     # Entries can only store sub refs
    my $arr     : ARRAY;	     # Can only store array ref
    my @hashes  : HASH;		     # Elements can only store hash refs
    my $glob    : GLOB;		     # Can only store a typeglob ref
    my $pattern : REGEX;	     # Can only store a qr'd regex
    my $ref2    : REF;		     # Can only store a meta-reference

    my $obj : Type(My::Class);	     # Can only store objects of (or
    				     # derived from) the specified class

    my $x : Type(/good|bad|ugly/);   # Can only store strings matching
    				     # the specified regex

    sub odd { no warnings; $_[0]%2 }

    my $guarded : Type(&odd);        # Can only store values for which
    				     # odd($value) returns true

    $date = 23;			     # okay
    $date = 32;			     # KABOOM!

    $rain[1] = 121.7;		     # okay
    $rain[1] = "lots";		     # KABOOM!

    $x = 'very good';		     # okay
    $x = 'excellent';		     # KABOOM!

    package My::Class::Der;
    use base 'My::Class';

    $obj = My::Class->new();	     # okay
    $obj = My::Class::Der->new();    # okay
    $obj = Other::Class->new();      # KABOOM!

    $guarded = 1;		     # okay
    $guarded = 2;		     # KABOOM!




=head1 DESCRIPTION

The Attribute::Types module provides 10 universally accessible 
attributes that can be used to create variables that accept assignments
of only specific types of data.

The attributes are:

=over

=item C<INTEGER>

Indicates that the associated scalar, or the elements of the associated array,
or the entries of the associated hash can only contain integer values (those
values that are internally represented as actual numbers
(or may be converted to actual numbers without generating a warning),
and for which C<int($value)==$value)>.

The attribute may also be specified with a range of integer values,
indicating a further restriction on the values the associated variable can
store. For example:

    my $x1 : INTEGER(1..100);	# Any int between 1 and 100
    my $x2 : INTEGER(-10..10);	# Any ine between -10 and 10
    my $x3 : INTEGER(0..);	# Any positive int
    my $x4 : INTEGER(..99);	# Any int < 100 (including negatives)

=item C<NUMBER>

Indicates that the associated scalar, or the elements of the associated array,
or the entries of the associated hash can only contain values that are
internally represented by (or silently convertible to) valid Perl numbers.

The attribute may also be specified with a range of numerical values,
indicating a further restriction on the values the associated variable can
store. For example:

    my $x1 : NUMBER(1.0..100.0);    # Any number between 1 and 100
    my $x2 : NUMBER(-10..10);       # Any number between -10 and 10
    my $x3 : NUMBER(0..);           # Any positive number
    my $x4 : NUMBER(..99.9);        # Any number < 99.9 (incl. negatives)

=item C<SCALAR>

Indicates that the associated scalar, or the elements of the associated array,
or the entries of the associated hash can only contain references to
scalars (i.e. only values for which C<ref($value) eq 'SCALAR'>).

=item C<ARRAY>

Indicates that the associated variable can only contain references to
arrays (i.e. only values for which C<ref($value) eq 'ARRAY'>).

=item C<HASH>

Indicates that the associated variable can only contain references to
hashes (i.e. only values for which C<ref($value) eq 'HASH'>).

=item C<CODE>

Indicates that the associated variable can only contain references to
subroutines (i.e. only values for which C<ref($value) eq 'CODE'>).

=item C<GLOB>

Indicates that the associated variable can only contain references to
typeglobs (i.e. only values for which C<ref($value) eq 'GLOB'>).

=item C<REF>

Indicates that the associated variable can only contain references to
other references (i.e. only values for which C<ref($value) eq 'REF'>).

=item C<REGEX>

Indicates that the associated variable can only contain references to
precompiled regular expressions (i.e. only values for which
C<ref($value) eq 'Regexp'>).

=item C<Type>

Used to specify class-wise or generic storage constraints on a variable.
There are three permitted syntaxes:

=over

=item C<Type(Class::Name)>

Indicates that the associated variable can only contain references to objects
belonging to the specified class, or to one of its derived classes.

=item C<Type(/pattern/)>

Indicates that the associated variable can only contain values that successfully
match the specified pattern.

=item C<Type(&subname)>

Indicates that the associated variable can only contain values for which the
specified subroutine returns true when passed the value as its first argument.

Note that anonymous subroutines cannot be used in this context (they are
run-time phenomena and types have to be set up at compile-time).

=back

=back

If the module is imported with a list of attribute names:

        use Attribute::Types qw(INTEGER HASH);

then only those attributes can be used to specify types.


=head1 CAVEAT

The type checking set up by this module is I<run-time> type-checking.
That is, the validity of an assignment is only checked when the assignment
operation is actually performed, not when it is compiled.


=head1 DIAGNOSTICS

=over 4

=item C<< Cannot assign I<value> to I<type> variable >>

The value being assigned is not consistent with the declared type of the
variable.


=item C<< Can't specify type attribute for CODE >>

Subroutines cannot be typed using the Attribute::Types attributes.


=item C<< Invalid type specifier: Type(I<garbage>) >>

The C<Type(...)> attribute can only be specified with a class name, a
pattern (in /.../), or a subroutine name.

=back

=head1 BLAME

This is all Nat Torkington's idea.

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS AND IRRITATIONS

There are undoubtedly serious bugs lurking somewhere in this code :-)
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

        Copyright (c) 2001, Damian Conway. All Rights Reserved.
      This module is free software. It may be used, redistributed
         and/or modified under the same terms as Perl itself.
