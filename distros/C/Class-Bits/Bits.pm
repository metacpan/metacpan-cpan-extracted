package Class::Bits;

use 5.006;

our $VERSION = '0.05';

# use strict;
use warnings::register;
use warnings ();

use integer;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(make_bits);

use Carp;
use Config;

use constant nvsize => $Config{nvsize}*8;

my %umax = ( 1  => 1,
	     2  => 3,
	     4  => 15,
	     8  => 255,
	     16 => 65535,
	     32 => 4294967295 );

my %smax = ( 1  => 0,
	     2  => 1,
	     4  => 7,
	     8  => 127,
	     16 => 32767,
	     32 => 2147483647 );

my %smin = ( 1  => -1,
	     2  => -2,
	     4  => -8,
	     8  => -128,
	     16 => -32768,
	     32 => -2147483648 );

my %sext = map { $_ => (~$smax{$_}) } keys(%smax);

my %signed = ( 's' => 1,
               'u' => 0,
               ''  => 0 );

sub make_bits {
    @_ & 1 and
	croak 'Class::Bits::bits called with an even number of arguments';

    my %names;
    my $offset=0;
    my $pkg=caller();

    while(@_) {
	my $name=shift;
	exists $names{$name} and
	    croak "repeated name '$name'";
	$names{$name}=1;

	my $spec=shift;
	$spec=~/^\s*([us]?)\s*(\d+)\s*$/ or
	    croak "invalid Class::Bits specification '$spec' for '$name'";
	my $sig=$signed{$1};
	my $size=$2;

	exists $smax{$size} or
	    croak "invalid Class::Bits size '$size' for '$name'";

	my $index=int(($offset+$size-1)/$size);
	$offset=($index+1)*$size;

	$pkg->{INDEX}{$name}=$index;
	$pkg->{SIZE}{$name}=$size;
	$pkg->{SIGNED}{$name}=$sig;

	# warn "$name: index=>$index, size=>$size, sig=>$sig";

	if ($sig) {
	    my $max=$smax{$size};
	    my $min=$smin{$size};
	    my $ext=$sext{$size};

	    *{"${pkg}::$name"}=sub {
		my $this=shift;
		if (@_) {
		    my $value=shift;
		    if ($value > $max or $value < $min) {
			warnings::warn "value $value for "
			    .ref($this)
				."::$name out of range [$min, $max]"
				    if warnings::enabled();
		    }
		    vec ($$this, $index, $size) = $value;
		}
		my $value=vec ($$this, $index, $size);
		if ($value & $ext) {
		    return $ext|$value;
		}
		return $value;
	    }
	}
	else {

	    my $max=$umax{$size};

	    *{"${pkg}::$name"}=sub {
		my $this=shift;
		if (@_) {
		    my $value=shift;
		    if (!defined($value)) {
			warnings::warnif('uninitialized',
					 "Uninitialized value passed to $name accessor");
			$value=0;
		    }
		    warnings::warnif("value $value for ".ref($this)."::$name out of range [0, $max]")
			    if ($value > $max or $value < 0);
		    vec ($$this, $index, $size) = $value;
		}
		else {
		    vec ($$this, $index, $size);
		}
	    };
	}
    }

    *{"${pkg}::new"}=sub {
	my $ref=shift;
	my ($class, $string);
	if (ref($ref)) {
	    $class=ref($ref);
	    $string=$$ref;
	}
	else {
	    $class=$ref;
	    $string="\0" x ((7+ $offset) >> 3)
	}
	
	$string=shift if @_ & 1;

	my $this=\$string;
	bless $this, $class;

	my %opts=@_;
	for my $k (keys %opts) {
	    $this->$k($opts{$k});
	}
	
	return $this;
    };

    *{"${pkg}::length"}=sub { $offset }
	unless exists $names{lenght};

    *{"${pkg}::keys"}=sub { keys %names }
	unless exists $names{keys};

    *{"${pkg}::as_hash"}=sub {
	my $this=shift;
	map { ($_, $this->$_ ) } keys %names
    }
	unless exists $names{as_hash};
}



1;
__END__

=head1 NAME

Class::Bits - Class wrappers around bit vectors

=head1 SYNOPSIS

  package MyClass;
  use Class::Bits;

  make_bits( a => 4,  # 0..15
             b => 1,  # 0..1
             c => 1,  # 0..1
             d => 2,  # 0..3
             e => s4  # -8..7
             f => s1  # -1..0
   );

   package;

   $o=MyClass->new(a=>12, d=>2);
   print "o->b is ", $o->b, "\n";

   print "bit vector is ", unpack("h*", $$o), "\n";

   $o2=$o->new();
   $o3=MyClass->new($string);

=head1 ABSTRACT

L<Class::Bits> creates class wrappers around bit vectors.

=head1 DESCRIPTION

L<Class::Bits> defines classes using bit vectors as storage.

Object attributes are stored in bit fields inside the bit vector. Bit
field sizes have to be powers of 2 (1, 2, 4, 8, 16 or 32).

There is a class constructor subroutine:

=over 4

=item make_bits( field1 => size1, field2 => size2, ...)

exports in the calling package a ctor, accessor methods, some
utility methods and some constants:

Sizes can be prefixed by C<s> or C<u> to define signedness of the
field. Default is unsigned.

=over 4

=item $class-E<gt>new()

creates a new object with all zeros.

=item $class-E<gt>new($bitvector)

creates a new object over $bitvector.

=item $class-E<gt>new(%fields)

creates a new object and initializes its fields with the values in
C<%fields>.

=item $obj-E<gt>new()

clones an object.


=item $obj-E<gt>$field()

=item $obj-E<gt>$field($value)

gets or sets the value of the bit field C<$field> inside the bit vector.

=item $class-E<gt>length

=item $obj-E<gt>lenght

returns the size in bits of the bit vector used for storage.

=item $class-E<gt>keys

=item $obj-E<gt>keys

returns an array with the names of the object attributes

=item $obj-E<gt>as_hash

returns a flatten hash with the object attributes, i.e.:

  my %values=$obj->as_hash;

=item %INDEX

hash with offsets as used by C<vec> perl operator (to get an offset in
bits, the value has to be multiplied by the corresponding bit field
size).

=item %SIZES

hash with bit field sizes in bits.

=item %SIGNED

hash with signedness of the fields

=back

Bit fields are packed in the bit vector in the order specified as
arguments to C<make_bits>.

Bit fields are padded inside the bit vector, i.e. a class created like

  make_bits(A=>1, B=>2, C=>1, D=>4, E=>8, F=>16);

will have the layout

  AxBBCxxx DDDDxxxx EEEEEEEE xxxxxxxx FFFFFFFF FFFFFFFF


=back


=head2 EXPORT

C<make_bits>


=head1 SEE ALSO

L<perlfunc/vec>, L<Class::Struct>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

