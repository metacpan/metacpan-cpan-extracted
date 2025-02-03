use utf8;
use strict;
if ( $] >= 5.007 ) {
	binmode (STDOUT, ":utf8");
}

# use Convert::CEGH; # this will import both the "enumerate" and "transliterate" functions.
#
# Import "enumerate" only:
#
use Convert::CEGH::Gematria 'enumerate';

print "פלא => ", enumerate ( "פלא" ), "\n";
print "አዳም => ", enumerate ( "አዳም" ), "\n";
print "מדא => ", enumerate ( "מדא" ), "\n";
print "ΑΔΑΜ => ", enumerate ( "ΑΔΑΜ" ), "\n";

print "עשוהי => ", enumerate ( "עשוהי" ), "\n";

print "ΙΕΟΥΣ => ", enumerate ( "ΙΕΟΥΣ" ), "\n";
print "ΧΡΙΣΤΟΣ => ", enumerate ( "ΧΡΙΣΤΟΣ" ), "\n";

print "\nUsing አበገደ enumeration (the default):\n";
print "  አዳም => ", enumerate ( "አዳም" ), "\n";
print "  ኢየሱስ => ", enumerate ( "ኢየሱስ" ), "\n";
print "  ክርስቶስ => ", enumerate ( "ክርስቶስ" ), "\n";
print "  አብርሃም => ", enumerate ( "አብርሃም " ), "\n";

$Convert::CEGH::Gematria::use_halehame = 1;
print "\nUsing ሀለሐመ enumeration:\n";
print "  አዳም => ", enumerate ( "አዳም" ), "\n";
print "  ኢየሱስ => ", enumerate ( "ኢየሱስ" ), "\n";
print "  ክርስቶስ => ", enumerate ( "ክርስቶስ" ), "\n";
print "  አብርሃም => ", enumerate ( "አብርሃም " ), "\n";
$Convert::CEGH::Gematria::use_halehame = 0;



__END__

=head1 NAME

gematria.pl - Demonstration of Gematria Calculations.

=head1 SYNOPSIS

./gematria.pl

=head1 DESCRIPTION

This is a simple demonstration script that presents examples
of gematria conversions for 10 sample words.  The script also
illustrates the "Halehame" Gematria usage.


=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Convert::CEGH::Gematria>

=cut
