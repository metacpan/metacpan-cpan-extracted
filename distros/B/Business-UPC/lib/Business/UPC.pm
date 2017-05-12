package Business::UPC;

# Copyright (c) 1998-2017 Rob Fugina <robf@fugina.com>

use strict;
use vars qw($VERSION);

$VERSION = '0.06';

# Preloaded methods go here.

sub new
{
   my $class = shift;
   my $value = shift;

   return undef if length($value) > 12;

   my ($number_system, $mfr_id, $prod_id, $check_digit) = unpack("AA5A5A", _zeropad($value));

   return undef unless $number_system =~ m/^\d$/;
   return undef unless $mfr_id =~ m/^\d{5}$/;
   return undef unless $prod_id =~ m/^\d{5}$/;
   return undef unless $check_digit =~ m/^[\dx]$/i;

   return undef if ($number_system == 0 && $mfr_id == 0 && $prod_id == 0);

   my $upc = bless {
	number_system => $number_system,
	mfr_id => $mfr_id,
	prod_id => $prod_id,
	check_digit => $check_digit,
	}, $class;

   return $upc;
}

# alternate constructor: for creating from a zero-supressed (type E) value
sub type_e
{
   my $class = shift;
   my $value = shift;

   return undef if length($value) > 8;

   my $expanded = _expand_upc_e($value);

   return new Business::UPC($expanded) if $expanded;
   return undef;
}

sub number_system
{
   my $attrname = 'number_system';
   my $self = shift;
   warn "UPC atribute '$attrname' is not settable." if (@_);
   return $self->{$attrname};
}

sub mfr_id
{
   my $attrname = 'mfr_id';
   my $self = shift;
   warn "UPC atribute '$attrname' is not settable." if (@_);
   return $self->{$attrname};
}

sub prod_id
{
   my $attrname = 'prod_id';
   my $self = shift;
   warn "UPC atribute '$attrname' is not settable." if (@_);
   return $self->{$attrname};
}

sub check_digit
{
   my $attrname = 'check_digit';
   my $self = shift;
   warn "UPC atribute '$attrname' is not settable." if (@_);
   return $self->{$attrname};
}

sub as_upc_a
{
   my $self = shift;
   return $self->number_system . $self->mfr_id . $self->prod_id . $self->check_digit;
}

sub as_upc_a_nocheck
{
   my $self = shift;
   return $self->number_system . $self->mfr_id . $self->prod_id;
}

sub as_upc
{
   my $self = shift;
   return $self->as_upc_a
}

sub as_upca_nocheckdigit
{
   my $self = shift;
   return $self->number_system . $self->mfr_id . $self->prod_id;
}

sub number_system_description
{
   my $self = shift;
   return $Business::UPC::NumberSystems{$self->number_system};
}

sub coupon_value_code
{
   my $self = shift;
   return undef unless $self->is_coupon;
   return substr($self->prod_id, -2);
}

sub coupon_value
{
   my $self = shift;
   return undef unless $self->is_coupon;
   return $Business::UPC::CouponValues{$self->coupon_value_code};
}

sub coupon_family_code
{
   my $self = shift;
   return undef unless $self->is_coupon;
   return substr($self->prod_id, 0, 3);
}

sub coupon_family_description
{
   my $self = shift;
   my $cfc = $self->coupon_family_code;
   return $Business::UPC::CouponFamilies{$cfc} || 'Unknown';
}

sub is_valid
{
   my $self = shift;
   return (_check_digit($self->as_upca_nocheckdigit) eq $self->check_digit);
}

sub is_coupon
{
   my $self = shift;
   return ($self->number_system eq '5');
}

sub fix_check_digit
{
   my $self = shift;
   $self->{check_digit} = _check_digit($self->as_upca_nocheckdigit);
   $self;
}

sub as_upc_e
{
   my $self = shift;

   my $upca = $self->as_upc_a;

   return $upca if ($upca =~ s/^0(\d{2})([012])0000(\d{3})(\d)$/0${1}${3}${2}${4}/);
   return $upca if ($upca =~ s/^0(\d{2}[3-9])00000(\d{2})(\d)$/0${1}${2}3${3}/);
   return $upca if ($upca =~ s/^0(\d{3}[1-9])00000(\d)(\d)$/0${1}${2}4${3}/);
   return $upca if ($upca =~ s/^0(\d{4}[1-9])0000([5-9])(\d)$/0${1}${2}${3}/);
   return undef;
}

# private functions: don't use these!

sub _check_digit
{
   my $num = shift;

   my @digits = split(//, $num);

   # To avoid warning when summing below.
   push @digits, 0;

   my $sum = 0;

   foreach my $i (0, 2, 4, 6, 8, 10)
   {
      $sum += 3 * ($digits[$i] || 0);
      $sum += $digits[$i+1] || 0;
   }

   return (10 - ($sum % 10)) % 10;
}

sub _zeropad
{
   my $num = shift;
   my $length = shift || 12;
   return sprintf("%0${length}s", $num);
}

sub _expand_upc_e
{
   my $upc_e = _zeropad(shift, 8);

   return undef if (length($upc_e) > 8);

   return $upc_e if ($upc_e =~ s/^0(\d{2})(\d{3})([012])([\dx])$/0${1}${3}0000${2}${4}/i);
   return $upc_e if ($upc_e =~ s/^0(\d{3})(\d{2})3([\dx])$/0${1}00000${2}${3}/i);
   return $upc_e if ($upc_e =~ s/^0(\d{4})(\d)4([\dx])$/0${1}00000${2}${3}/i);
   return $upc_e if ($upc_e =~ s/^0(.....)([5-9])([\dx])$/0${1}0000${2}${3}/i);
   return undef;
}

BEGIN
{
   %Business::UPC::NumberSystems = (
	'0' => 'Regular Item',
	'1' => 'Reserved',
	'2' => 'Random-Weight Item',
	'3' => 'National Drug/Health-Related Item',
	'4' => 'For Private Use',
	'5' => 'Coupon',
	'6' => 'Regular Item',
	'7' => 'Regular Item',
	'8' => 'Reserved',
	'9' => 'Reserved',
	);
   %Business::UPC::CouponFamilies = (
	'000' => 'Anything from Same Manufacturer',
	'001' => 'Reserved',
	'002' => 'Reserved',
	'003' => 'Reserved',
	'004' => 'Reserved',
	'005' => 'Reserved',
	'006' => 'Reserved',
	'007' => 'Reserved',
	'008' => 'Reserved',
	'009' => 'Reserved',
	'990' => 'Reserved',
	'991' => 'Reserved',
	'992' => 'Reserved',
	'993' => 'Reserved',
	'994' => 'Reserved',
	'995' => 'Reserved',
	'996' => 'Reserved',
	'997' => 'Reserved',
	'998' => 'Reserved',
	'999' => 'Reserved',
	);
   %Business::UPC::CouponValues = (
	'00' => 'Checker Intervention',
	'01' => 'Free Merchandise',
	'02' => 'Buy 4 or more, get 1 free (same product)',
	'03' => '$1.10',
	'04' => '$1.35',
	'05' => 'Reserved for Future Use',
	'06' => '$1.60',
	'07' => 'Reserved for Future Use',
	'08' => 'Reserved for Future Use',
	'09' => 'Reserved for Future Use',
	'10' => '$0.10',
	'11' => '$1.85',
	'12' => '$0.12',
	'13' => 'Reserved for Future Use',
	'14' => 'Buy 1, get 1 free (same product)',
	'15' => '$0.15',
	'16' => 'Buy 2, get 1 free (same product)',
	'17' => '$2.10',
	'18' => '$2.60',
	'19' => 'Buy 3, get 1 free (same product)',
	'20' => '$0.20',
	'21' => 'Buy 2 or more, get $0.35 off',
	'22' => 'Buy 2 or more, get $0.40 off',
	'23' => 'Buy 2 or more, get $0.45 off',
	'24' => 'Buy 2, get $0.50 off',
	'25' => '$0.25',
	'26' => '$2.85',
	'27' => 'Reserved for Future Use',
	'28' => 'Buy 2, get $0.55 off',
	'29' => '$0.29',
	'30' => '$0.30',
	'31' => 'Buy 2 or more, get $0.60 off',
	'32' => 'Buy 2 or more, get $0.75 off',
	'33' => 'Buy 2, get $1.00 off',
	'34' => 'Buy 2 or more, get $1.25 off',
	'35' => '$0.35',
	'36' => 'Buy 2 or more, get $1.50 off',
	'37' => 'Buy 3 or more, get $0.25 off',
	'38' => 'Buy 3 or more, get $0.30 off',
	'39' => '$0.39',
	'40' => '$0.40',
	'41' => 'Buy 3 or more, get $0.50 off',
	'42' => 'Buy 3 or more, get $1.00 off',
	'43' => 'Buy 2 or more, get $1.10 off',
	'44' => 'Buy 2 or more, get $1.35 off',
	'45' => '$0.45',
	'46' => 'Buy 2 or more, get $1.60 off',
	'47' => 'Buy 2 or more, get $1.75 off',
	'48' => 'Buy 2 or more, get $1.85 off',
	'49' => '$0.49',
	'50' => '$0.50',
	'51' => 'Buy 2 or more, get $2.00 off',
	'52' => 'Buy 3 or more, get $0.55 off',
	'53' => 'Buy 2 or more, get $0.10 off',
	'54' => 'Buy 2 or more, get $0.15 off',
	'55' => '$0.55',
	'56' => 'Buy 2 or more, get $0.20 off',
	'57' => 'Buy 2, get $0.25 off',
	'58' => 'Buy 2, get $0.30 off',
	'59' => '$0.59',
	'60' => '$0.60',
	'61' => '$10.00',
	'62' => '$9.50',
	'63' => '$9.00',
	'64' => '$8.50',
	'65' => '$0.65',
	'66' => '$8.00',
	'67' => '$7.50',
	'68' => '$7.00',
	'69' => '$0.69',
	'70' => '$0.70',
	'71' => '$6.50',
	'72' => '$6.00',
	'73' => '$5.50',
	'74' => '$5.00',
	'75' => '$0.75',
	'76' => '$1.00',
	'77' => '$1.25',
	'78' => '$1.50',
	'79' => '$0.79',
	'80' => '$0.80',
	'81' => '$1.75',
	'82' => '$2.00',
	'83' => '$2.25',
	'84' => '$2.50',
	'85' => '$0.85',
	'86' => '$2.75',
	'87' => '$3.00',
	'88' => '$3.25',
	'89' => '$0.89',
	'90' => '$0.90',
	'91' => '$3.50',
	'92' => '$3.75',
	'93' => '$4.00',
	'94' => '$4.25',
	'95' => '$0.95',
	'96' => '$4.50',
	'97' => '$4.75',
	'98' => 'Buy 2 or more, get $0.65 off',
	'99' => '$0.99',
	);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# documentation:

=head1 NAME

Business::UPC - Perl extension for manipulating Universal Product Codes

=head1 SYNOPSIS

   use Business::UPC;

   # Constructors:
   # create a UPC object using standard (type-A) UPC
   $upc = new Business::UPC('012345678905');
   # create a UPC object using zero-supressed (type-E) UPC
   $upc = type_e Business::UPC('01201303');

   # is the UPC valid (correct check digit)?
   $upc->is_valid;

   # correct the check digit
   $upc->fix_check_digit;

   # get the numeric string:
   $upc->as_upc;	# same as $upc->as_upc_a;
   $upc->as_upc_a;
   $upc->as_upc_e;

   # get the components;
   $upc->number_system;		# UPC number system character
   $upc->mfr_id;		# Manufacturer ID
   $upc->prod_id;		# Product ID
   $upc->check_digit;		# Check Digit

   # more information about the components:
   $upc->number_system_description	# explain number_system

   # methods specific to coupon UPC codes:
   $upc->is_coupon;
   $upc->coupon_family_code;		# 3-digit family code
   $upc->coupon_family_description;	# explain above
   $upc->coupon_value_code;		# 2-digit value code
   $upc->coupon_value;			# explain above

=head1 DESCRIPTION

More detail to come later...

=head1 AUTHOR

Rob Fugina, robf@fugina.com

=head1 SEE ALSO

perl(1).

=cut
