use Carp;

# check CFITSIO status
sub check_status {
    my $s = shift;
    if ($s != 0) {
	my $txt;
      Astro::FITS::CFITSIO::fits_get_errstatus($s,$txt);
	carp "CFITSIO error: $txt";
	return 0;
    }

    return 1;
}

1;

=head1 check_status( )

	$retval = check_status($status);

Checks the CFITSIO status variable. If it indicates an error, the
corresponding CFITSIO error message is carp()ed,
and a false value is returned. If the passed status
does not indicate an error, then a true value is returned and nothing
else is done

=cut
