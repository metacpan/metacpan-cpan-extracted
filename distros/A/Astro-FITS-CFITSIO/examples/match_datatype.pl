use Carp;

#
# find appropriate CFITSIO datatype for a given piddle type.
# Can be passed the piddle itself or a PDL::Type token (e.g.,
# float() with no args).
#
sub match_datatype {

    my $arg = shift;

    my $pdl_type;
    if (UNIVERSAL::isa($arg,'PDL')) {
	$pdl_type = $arg->get_datatype;
    }
    elsif (UNIVERSAL::isa($arg,'PDL::Type')) {
	$pdl_type = $arg->[0];
    }
    else {
	croak "argument should be a PDL object or PDL::Type token";
    }

    my $pdl_size = PDL::Core::howbig($pdl_type);

    my @cfitsio_possible_types;
    # test for real datatypes
    if ($pdl_type == float(1)->get_datatype or
	$pdl_type == double(1)->get_datatype
	)
    {
	@cfitsio_possible_types = (
				 Astro::FITS::CFITSIO::TDOUBLE(),
				 Astro::FITS::CFITSIO::TFLOAT(),
				   );
    }
    elsif ($pdl_type == short(1)->get_datatype or
	   $pdl_type == long(1)->get_datatype
	   )
    {
	@cfitsio_possible_types = (
				 Astro::FITS::CFITSIO::TSHORT(),
				 Astro::FITS::CFITSIO::TINT(),
				 Astro::FITS::CFITSIO::TLONG(),
				   );
    }
    elsif ($pdl_type == ushort(1)->get_datatype or
	   $pdl_type == byte(1)->get_datatype
	   )
    {
	@cfitsio_possible_types = (
				 Astro::FITS::CFITSIO::TBYTE(),
				 Astro::FITS::CFITSIO::TUSHORT(),
				 Astro::FITS::CFITSIO::TUINT(),
				 Astro::FITS::CFITSIO::TULONG(),
				   );
    }
    else
    {
	croak "cannot handle PDL type $pdl_type";
    }


    foreach my $cfitsio_type (@cfitsio_possible_types) {
	return $cfitsio_type if $pdl_size == Astro::FITS::CFITSIO::sizeof_datatype($cfitsio_type);
    }

    croak "no CFITSIO type for PDL type $pdl_type";
}

1;

=head1 match_datatype( )

	$cfitsio_type = match_datatype($piddle);
	$cfitsio_type = match_datatype(long); # or short, or float, etc.

PDL datatypes are always guaranteed to be the same size on all architectures,
whereas CFITSIO datatypes (TLONG, for example), will vary on some
architectures since they correspond to the C datatypes on that system. This
poses a problem for Perl scripts which wish to read FITS data into piddles,
and do so in a portable manner. This routine takes a PDL object or PDL::Types
token (returned by float() and friends when given no arguments), and returns
the same-sized CFITSIO datatype, suitable for passing to routines such as
fits_read_col().

=cut
