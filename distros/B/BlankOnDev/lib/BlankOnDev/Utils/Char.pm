package BlankOnDev::Utils::Char;
use strict;
use warnings FATAL => 'all';

# Use Module :

# Version :
our $VERSION = '0.1005';

# Subroutine for split character based character :
# ------------------------------------------------------------------------
=head1 SUBROUTINE split_bchar()

	Deskripsi subrotuine split_bchar() :
	----------------------------------------
	Subroutine yang berfungsi untuk split string berdasarkan karakter.

	Parameter subrotuine split_bchar() :
	----------------------------------------
	$string
	$delimiter

	Output Parameter :
	----------------------------------------
	array data type.

=cut
sub split_bchar {
    # Define parameter Subroutine :
    my ($self, $string, $delimiter) = @_;

    # Split :
    my @split = split /$delimiter/, $string;

    # Return :
    return @split;
}
# End of Subroutine for split character based character
# ===========================================================================================================

# Subroutine for split string based length :
# ------------------------------------------------------------------------
=head1 SUBROUTINE split_blen()

	Deskripsi subroutine split_blen() :
	----------------------------------------
	Subroutine yang berfungsi untuk split string berdasarkan jumlah karakter.

	Parameter subroutine split_blen() :
	----------------------------------------
	$string
	$length

	Output Parameter :
	----------------------------------------
	array data type.

=cut
sub split_blen {
	# Define parameter subroutine :
    my ($self, $string, $length) = @_;

    # Split :
    my $this_length = 'A'.$length;
    my $len = "." x $length;
    my @data = ($string =~ m/$len/g);

    # Return :
    return @data;
}
# End of Subroutine for split string based length
# ===========================================================================================================

1;
__END__
#