package Business::AU::ACN;
use base qw/Exporter/;
use vars qw/$VERSION/;
$VERSION = "0.31";

=head1 NAME

Business::AU::ACN - Validate ACN - Australian Company Number

=head1 SYNOPSIS

    use Business::AU::ACN;
 
    print Business::AU::ACN::validate("123 456 789");

=head1 DESCRIPTION

NOTE: This also covers ARSN (Australian Registerted Scheme Numbers) and 
ARBN (Australian Registered Body Numbers), but not ABN (Australian Business
Numbers).

=head1 NOTES

This is bound to change (damn content management system URLs) but here is where
the original ifnormation is:

http://www.asic.gov.au/asic/ASIC_INFOCO.NSF/byid/CA256AE900038AEACA256AFB008053ED?opendocument

=head1 AUTHOR

Scott Penrose <scottp@dd.com.au>, 
Tom Harrison <tomh@apnic.net>

=head1 SEE ALSO

L<Business:AU::ACN>

=cut

sub validate {
	my ($acn) = @_;
	my @acn = _split($acn);
	
	# check length is 9
	unless (@acn == 9) {
		return "invalid length (must be 9)";
	}

	# add accumulation
	my $acc = 0;
	for (my $i = 0; $i < 8; $i++) {
		$acc += $acn[$i] * (8 - $i);
	}
	$acc = 10 - ($acc % 10);
        if ($acc == 10) {
            $acc = 0;
        }

	# check it is valid
	if ($acn[8] == $acc) {
		return "valid";
	}

	return "invalid sum";
}

sub _split {
	my ($acn) = @_;
	# Original change was - $acn =~ s/[^0-9]//g;
	# Now we just allow white space to be removed
	$acn =~ s/\s//g;
	return split(//, $acn);
}

=head2 pretty($acn)

This prints out a valid pretty print of an ACN. The standards says that it must
be showed in groups of three (nnn nnn nnn).

=cut

sub pretty {
	my ($acn) = @_;
	my @acn = _split($acn);
	if (validate($acn) eq "valid") {
		return join('', @acn[0..2], ' ', @acn[3..5], ' ', @acn[6..8]);
	} else {
		return "invalid";
	}
}

1;

