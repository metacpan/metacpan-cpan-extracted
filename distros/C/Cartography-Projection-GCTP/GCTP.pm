package Cartography::Projection::GCTP;

use 5.0.8;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Cartography::Projection::GCTP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	P_GEO P_UTM P_SPCS P_ALBERS P_LAMCC P_MERCAT P_PS P_POLYC P_EQUIDC
	P_TM P_STEREO P_LAMAZ P_AZMEQD P_GNOMON P_ORTHO P_GVNSP P_SNSOID P_EQRECT
	P_MILLER P_VGRINT P_HOM P_ROBIN P_SOM P_ALASKA P_GOOD P_MOLL P_IMOLL
	P_HAMMER P_WAGIV P_WAGVII P_OBEQA P_USDEF

	D_WGS84

	U_RADIAN U_FEET U_METER U_SECOND U_DEGREE U_INT_FEET U_STPLN_TABLE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Cartography::Projection::GCTP::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Cartography::Projection::GCTP', $VERSION);

# Preloaded methods go here.



######################################################

use constant P_GEO => 0;
use constant P_UTM => 1;
use constant P_SPCS => 2;
use constant P_ALBERS => 3;
use constant P_LAMCC => 4;
use constant P_MERCAT => 5;
use constant P_PS => 6;
use constant P_POLYC => 7;
use constant P_EQUIDC => 8;
use constant P_TM => 9;
use constant P_STEREO => 10;
use constant P_LAMAZ => 11;
use constant P_AZMEQD => 12;
use constant P_GNOMON => 13;
use constant P_ORTHO => 14;
use constant P_GVNSP => 15;
use constant P_SNSOID => 16;
use constant P_EQRECT => 17;
use constant P_MILLER => 18;
use constant P_VGRINT => 19;
use constant P_HOM => 20;
use constant P_ROBIN => 21;
use constant P_SOM => 22;
use constant P_ALASKA => 23;
use constant P_GOOD => 24;
use constant P_MOLL => 25;
use constant P_IMOLL => 26;
use constant P_HAMMER => 27;
use constant P_WAGIV => 28;
use constant P_WAGVII => 29;
use constant P_OBEQA => 30;
use constant P_USDEF => 99;

use constant U_RADIAN => 0;
use constant U_FEET => 1;
use constant U_METER => 2;
use constant U_SECOND => 3;
use constant U_DEGREE => 4;
use constant U_INT_FEET => 5;
use constant U_STPLN_TABLE => 6;

use constant D_WGS84 => 12;


######################################################

use vars qw[$ERROR_CODE];

sub projectCoordinatePair {
	my(
		$proto,
		$in_x, $in_y,
		$in_sys, $in_zone, $in_params, $in_unit, $in_datum,
		$out_sys, $out_zone, $out_params, $out_unit, $out_datum
	) = @_;
#print STDERR "params=[", (join ';', @_), "]\n";
	$ERROR_CODE = 0;
	my($out_x, $out_y) = (0, 0);
	_exec_gctp_interface(
		$in_x, $in_y, $in_sys, $in_zone,
		$in_params->[0], $in_params->[1], $in_params->[2], $in_params->[3],
		$in_params->[4], $in_params->[5], $in_params->[6], $in_params->[7],
		$in_params->[8], $in_params->[9], $in_params->[10], $in_params->[11],
		$in_params->[12], $in_params->[13], $in_params->[14],
		$in_unit, $in_datum,
		$out_x, $out_y, $out_sys, $out_zone,
		$out_params->[0], $out_params->[1], $out_params->[2], $out_params->[3],
		$out_params->[4], $out_params->[5], $out_params->[6], $out_params->[7],
		$out_params->[8], $out_params->[9], $out_params->[10], $out_params->[11],
		$out_params->[12], $out_params->[13], $out_params->[14],
		$out_unit, $out_datum,
		$ERROR_CODE
	);
	return if $ERROR_CODE;
	return($out_x, $out_y);
}

sub getErrorCode {
	return $ERROR_CODE;
}





# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Cartography::Projection::GCTP - Perl extension for gctpc projection library (deprecated)

=head1 SYNOPSIS

  use Cartography::Projection::GCTP;
	
=head1 DESCRIPTION

  Note: this module is only for compatibility with old applications that use GCTPc.
  All new projects should use Geo::Proj4 with is a wrapper around libproj4.

  my($out_x, $out_y) = Cartography::Projection::GCTP->projectCoordinatePair(
                $in_x, $in_y,
                $in_sys, $in_zone, $in_params, $in_unit, $in_datum,
                $out_sys, $out_zone, $out_params, $out_unit, $out_datum
  ) or die "Projection failed.  Error code is " . Cartography::Projection::GCTP->getErrorCode;

  See GCTP docs for explanation of parameters.  $in_params and $out_params are array
  references to the 15-element projection parameter arrays.

  Some non-exported constants are defined:
  Cartography::Projection::GCTP->P_*    projection codes
  Cartography::Projection::GCTP->U_*    unit codes
  
  For example, the Cartography::Projection::GCTP->P_GEO constant is the code for the geographic
  coordinate system.  See the GCTP docs for a complete list of projection codes.

=head2 EXPORT

None by default.

=head1 SEE ALSO

The GCTPc library by the EROS Data Center.

=head1 AUTHOR

Dan Stahlke <dstahlke@gi.alaska.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 Dan Stahlke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
