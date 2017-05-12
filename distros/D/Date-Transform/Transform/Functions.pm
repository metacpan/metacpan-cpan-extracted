package Date::Transform::Functions;
## SHOULD THIS BE ITS OWN PACKAGE SPACE
## NO.  These are not methods but functions.

use 5.006;
use strict;
use warnings;
use Carp;
use Switch 'Perl6';
use Tie::IxHash;

require Exporter;
use AutoLoader qw(AUTOLOAD);
our @ISA = qw( Exporter  );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Date::Transform::Functions ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = (
    'all' => [
        qw(
          iI_p_to_strftime_H
          Y_to_strftime_y
          bh_to_strftime_m
          B_to_strftime_m
          m_to_strftime_m
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  iI_p_to_strftime_H
  Y_to_strftime_y
  bh_to_strftime_m
  B_to_strftime_m
  m_to_strftime_m
);

our $VERSION = '0.11';

# Preloaded methods go here.

## This collection of functions changes provide the transformations of the
## various formats.

## SUBROUTINE: Ii_and_p_to_H
## 	Transforms the hours and AM/PM to strftime H
##
sub iI_p_to_strftime_H {

    my $i = shift;
    my $p = shift;

    $i = 0 if ( $i == 12 );
    $i += 12 if ( $p =~ /pm/i );

    return $i;

}    # END SUBROUTINE: iI_p_to_strftime_H

## SUBROUTINE: Y_to_strftime_y
##	Transform year(Y) to year(y) format.
sub Y_to_strftime_y {

    my $Y = shift;

    return ( $Y - 1900 );

}    # END SUBROUTINE: Y_to_strftime_y

## SUBROUTINE: bh_to_strftime_m
## 	Transforms month in b or h format to m format suitable for strftime input.
##
sub bh_to_strftime_m {

    my $bh = shift;

    given($bh) {

        when /jan/i { return 0; }
        when /feb/i { return 1; }
        when /mar/i { return 2; }
        when /apr/i { return 3; }
        when /may/i { return 4; }
        when /jun/i { return 5; }
        when /jul/i { return 6; }
        when /aug/i { return 7; }
        when /sep/i { return 8; }
        when /Oct/i { return 9; }    # Note: Reserved keyword oct.
        when /nov/i { return 10; }
        when /dec/i { return 11; }

    };

    carp("Did not match a valid month.\n");

}    # END SUBROUTINE: bh_to_strftime_m

## SUBROUTINE: B_to_strftime_m
## 	Transforms month from B format to m format suitable for
## 	strftime input.
sub B_to_strftime_m {

    my $B = shift;

    given($B) {

        when /january/i   { return 0; }
        when /february/i  { return 1; }
        when /march/i     { return 2; }
        when /april/i     { return 3; }
        when /may/i       { return 4; }
        when /june/i      { return 5; }
        when /july/i      { return 6; }
        when /august/i    { return 7; }
        when /september/i { return 8; }
        when /october/i   { return 9; }    # Note: Reserved keyword oct.
        when /november/i  { return 10; }
        when /december/i  { return 11; }

    };

    carp("Did not match a valid month.\n");

}    # END SUBROUTINE: B_to_strftime_m

# stftimeformat uses 0-11 for the month.
sub m_to_strftime_m {

    # my $m = shift;
    my $m = shift;
    $m = $m - 1;
    return $m;

    # $m--;
    #	my $function = sub {
    #		my $matches = shift;
    #		return $matches->FETCH('m') - 1;
    #	};

    #	return $function;
}

1;

__END__;