package CTK::TFVals; # $Id: TFVals.pm 192 2017-04-28 20:40:38Z minus $
use strict;

=head1 NAME

CTK::TFVals - True & False values conversions

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK::TFVals;

    # Undef conversions
    uv2zero( $value ); # Returns 0 if value is undef
    uv2null( $value ); # Returns "" if value is undef (null/empty/void)
                       # Aliases:  uv2empty, uv2void

    # False conversions
    fv2undef( $value ); # Returns undef if value is false
    fv2zero( $value ); # Returns 0 if value is false
    fv2null( $value ); # Returns "" if value is false (null/empty/void)
                       # Aliases:  fv2empty, fv2void

    # True conversions
    tv2num( $value ); # Returns 0 unless value ~ ([+-])?\d+
                      # Aliases: tv2number
                      # Check-function: is_num
    tv2flt( $value ); # Returns 0 unless value ~ ([+-])?\d+\.?\d*
                      # Aliases: tv2float
                      # Check-function: is_flt
    tv2int( $value ); # Returns 0 unless value ~ \d{1,11}
                      # Returns 0 unless value >= 0 && < 99999999999
                      # Check-function: is_int
    tv2int8( $value ); # Returns 0 unless value >= 0 && < 255
                       # Check-function: is_int8
    tv2int16( $value ); # Returns 0 unless value >= 0 && < 65535
                        # Check-function: is_int16
    tv2int32( $value ); # Returns 0 unless value >= 0 && < 4294967295
                        # Check-function: is_int32
    tv2int64( $value ); # Returns 0 unless value >= 0 && < 2**64
                        # Check-function: is_int64
    tv2intx( $value, $x ); # Returns 0 unless value >= 0 && < 2**$x
                        # Check-function: is_intx

=head1 DESCRIPTION

True & False values conversions

=head2 FUNCTIONS

=over 8

=item B<uv2zero>

This function returns the 0 value if argument is undef.

    uv2zero( $value );

=item B<uv2null>

This function returns the "" value if argument is undef.

    uv2null( $value );

=item B<uv2empty>

See L</"uv2null">

=item B<uv2void>

See L</"uv2null">

=item B<fv2undef>

This function returns the undev value if argument is false.

    fv2undef( $value );

=item B<fv2zero>

This function returns the 0 value if argument is false.

    fv2zero( $value );

=item B<fv2null>

This function returns the "" value if argument is false.

    fv2null( $value );

=item B<fv2empty>

See L</"fv2null">

=item B<fv2void>

See L</"fv2null">

=item B<tv2num>

This function returns the 0 value unless argument ~ ([+-])?\d+

    tv2num( $value );

=item B<tv2number>

See L</"tv2num">

=item B<tv2flt>

This function returns the 0 value unless argument ~ ([+-])?\d+\.?\d*

    tv2flt( $value );

=item B<tv2float>

See L</"tv2flt">

=item B<tv2int>

This function returns the 0 value unless argument ~ \d{1,11} and
argument value > 0 && < 99999999999

    tv2int( $value );

=item B<tv2int8>

This function returns the 0 value unless argument value >= 0 && < 255

    tv2int8( $value );

=item B<tv2int16>

This function returns the 0 value unless argument value >= 0 && < 65535

    tv2int16( $value );

=item B<tv2int32>

This function returns the 0 value unless argument value >= 0 && < 4294967295

    tv2int32( $value );

=item B<tv2int64>

This function returns the 0 value unless argument value >= 0 && < 2**64

    tv2int64( $value );

=item B<tv2intx>

This function returns the 0 value unless argument value >= 0 && < 2**$x

    tv2int64( $value, $x );

=item B<is_num>

This function returns true if argument ~ ([+-])?\d+

    is_num( $value );

=item B<is_flt>

This function returns true if argument ~ ([+-])?\d+\.?\d*

    is_flt( $value );

=item B<is_int>

This function returns true if argument ~ \d{1,20} and
argument value >= 0 && < 99999999999999999999

    is_int( $value );

=item B<is_int8>

This function returns true if argument value >= 0 && < 255

    is_int8( $value );

=item B<is_int16>

This function returns true if argument value >= 0 && < 65535

    is_int16( $value );

=item B<is_int32>

This function returns true if argument value >= 0 && < 4294967295

    is_int32( $value );

=item B<is_int64>

This function returns true if argument value >= 0 && < 2**64

    is_int64( $value );

=item B<is_intx>

This function returns true if argument value >= 0 && < 2**$x

    is_intx( $value, $x );

=back

=head2 TAGS

=head3 ALL

Export all subroutines:

L</"uv2zero">, L</"uv2null">, L</"uv2empty">, L</"uv2void">,
L</"fv2undef">, L</"fv2zero">, L</"fv2null">, L</"fv2empty">, L</"fv2void">,
L</"tv2num">, L</"tv2number">, L</"is_num">,
L</"tv2flt">, L</"tv2float">, L</"is_flt">,
L</"tv2int">, L</"is_int">,
L</"tv2int8">, L</"is_int8">,
L</"tv2int16">, L</"is_int16">,
L</"tv2int32">, L</"is_int32">,
L</"tv2int64">, L</"is_int64">,
L</"tv2intx">, L</"is_intx">

=head3 DEFAULT

L</"uv2zero">, L</"uv2null">, L</"uv2empty">, L</"uv2void">,
L</"fv2undef">, L</"fv2zero">, L</"fv2null">, L</"fv2empty">, L</"fv2void">,
L</"tv2num">, L</"tv2int">, L</"tv2flt">

=head3 UNDEF

L</"uv2zero">, L</"uv2null">, L</"uv2empty">, L</"uv2void">

=head3 FALSE

L</"fv2undef">, L</"fv2zero">, L</"fv2null">, L</"fv2empty">, L</"fv2void">

=head3 TRUE

L</"tv2num">, L</"tv2number">, L</"tv2flt">, L</"tv2float">, L</"tv2int">,
L</"tv2int8">, L</"tv2int16">, L</"tv2int32">, L</"tv2int64">, L</"tv2intx">

=head3 CHCK

L</"is_num">, L</"is_flt">, L</"is_int">, L</"is_int8">, L</"is_int16">,
L</"is_int32">, L</"is_int64">, L</"is_intx">

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use base qw /Exporter/;

# default
our @EXPORT = (qw/
        uv2zero uv2null uv2empty uv2void
        fv2undef fv2zero fv2null fv2empty fv2void
        tv2num tv2int tv2flt
            /);
# Required
our @EXPORT_OK = (qw/
        uv2zero uv2null uv2empty uv2void
        fv2undef fv2zero fv2null fv2empty fv2void
        tv2num tv2number is_num
        tv2flt tv2float is_flt
        tv2int is_int
        tv2int8 is_int8
        tv2int16 is_int16
        tv2int32 is_int32
        tv2int64 is_int64
        tv2intx is_intx
    /);
our %EXPORT_TAGS = (
        DEFAULT  => [@EXPORT],
        ALL      => [@EXPORT_OK],
        UNDEF    => [qw/
                uv2zero uv2null uv2empty uv2void
            /],
        FALSE    => [qw/
                fv2undef fv2zero fv2null fv2empty fv2void
            /],
        TRUE     => [qw/
                tv2num tv2number
                tv2flt tv2float
                tv2int tv2int8 tv2int16 tv2int32 tv2int64 tv2intx
            /],
        CHCK     => [qw/
                is_num is_flt is_int is_int8 is_int16 is_int32 is_int64 is_intx
            /],
    );

sub uv2zero($) {
    my $v = shift;
    return 0 unless defined $v;
    return $v;
}
sub uv2null($) {
    my $v = shift;
    return '' unless defined $v;
    return $v;
}
sub uv2empty($) { goto &uv2null }
sub uv2void($) { goto &uv2null }
sub fv2undef($) {
    my $v = shift;
    return undef unless $v;
    return $v;
}
sub fv2zero($) {
    my $v = shift;
    return 0 unless $v;
    return $v;
}
sub fv2null($) {
    my $v = shift;
    return '' unless $v;
    return $v;
}
sub fv2empty($) { goto &fv2null }
sub fv2void($) { goto &fv2null }
sub tv2num($) {
    my $tv = shift;
    return is_num($tv) ? $tv : 0;
}
sub tv2number($) { goto &tv2num }
sub is_num($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if $v =~ /^[+\-]?[0-9]{1,20}$/; # 64 bit
    return 0;
}
sub tv2flt($) {
    my $tv = shift;
    return is_flt($tv) ? $tv : 0;
}
sub tv2float($) { goto &tv2flt }
sub is_flt($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if $v =~ /^[+\-]?[0-9]{1,20}\.?[0-9]*$/; # 64 bit min
    return 0;
}
sub tv2int($) {
    my $tv = shift;
    return is_int($tv) ? $tv : 0;
}
sub is_int($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if $v =~ /^[0-9]{1,20}$/; # 64 bit max
    return 0;
}
sub tv2int8($) {
    my $tv = shift;
    return is_int8($tv) ? $tv : 0;
}
sub is_int8($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if ($v =~ /^[0-9]{1,3}$/) && ($v >= 0) && ($v < 2**8);
    return 0;
}
sub tv2int16($) {
    my $tv = shift;
    return is_int16($tv) ? $tv : 0;
}
sub is_int16($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if ($v =~ /^[0-9]{1,5}$/) && ($v >= 0) && ($v < 2**16);
    return 0;
}
sub tv2int32($) {
    my $tv = shift;
    return is_int32($tv) ? $tv : 0;
}
sub is_int32($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if ($v =~ /^[0-9]{1,10}$/) && ($v >= 0) && ($v < 2**32);
    return 0;
}
sub tv2int64($) {
    my $tv = shift;
    return is_int64($tv) ? $tv : 0;
}
sub is_int64($) {
    my $v = shift;
    return 0 unless defined $v;
    return 1 if ($v =~ /^[0-9]{1,20}$/) && ($v >= 0) && ($v < 2**64);
    return 0;
}

sub tv2intx($$) {
    my $tv = shift;
    my $x = shift || 0;
    return is_intx($tv, $x) ? $tv : 0;
}
sub is_intx($$) {
    my $v = shift;
    my $x = shift || 0;
    return 0 unless $x && is_int8($x) && ($x >=0) && ($x <= 64);
    return 0 unless defined $v;
    return 1 if ($v =~ /^[0-9]{1,20}$/) && ($v >= 0) && ($v < 2**$x);
    return 0;
}

1;
