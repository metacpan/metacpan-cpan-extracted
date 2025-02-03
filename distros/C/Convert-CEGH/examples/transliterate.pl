use utf8;
use strict;
if ( $] >= 5.007 ) {
	binmode (STDOUT, ":utf8");
}

# use Convert::CEGH; # this will import both the "enumerate" and "transliterate" functions.
#
# Import "transliterate" only:
#
use Convert::CEGH::Transliterate 'transliterate';

my $word = "አዳም";

my $coptic = transliterate ( "cop", $word );
my $ethio  = transliterate ( "eth", $word );
my $greek  = transliterate ( "ell", $word );
my $hebrew = transliterate ( "heb", $word );

print "Ge'ez  ➡ Coptic ➡ Ge'ez ➡ Hebrew ➡ Greek\n";
print "  $word  ➡    $coptic ➡   $ethio ➡    $hebrew ➡   $greek\n";

my $copticC = transliterate ( "co", $coptic );
my $ethioC  = transliterate ( "et", $coptic );
my $greekC  = transliterate ( "el", $coptic );
my $hebrewC = transliterate ( "he", $coptic );

print "Coptic ➡ Coptic ➡ Ge'ez ➡ Hebrew ➡ Greek\n";
print "   $coptic ➡    $copticC ➡   $ethioC ➡    $hebrewC ➡   $greekC\n";

my $copticE = transliterate ( "co", $ethio );
my $ethioE  = transliterate ( "et", $ethio );
my $greekE  = transliterate ( "el", $ethio );
my $hebrewE = transliterate ( "he", $ethio );

print "Ge'ez  ➡ Coptic ➡ Ge'ez ➡ Hebrew ➡ Greek\n";
print "  $ethio  ➡    $copticE ➡   $ethioE ➡    $hebrewE ➡   $greekE\n";

my $copticG = transliterate ( "co", $greek );
my $ethioG  = transliterate ( "et", $greek );
my $greekG  = transliterate ( "el", $greek );
my $hebrewG = transliterate ( "he", $greek );

print "Greek  ➡ Coptic ➡ Ge'ez ➡ Hebrew ➡ Greek\n";
print "  $greek  ➡    $copticG ➡   $ethioG ➡    $hebrewG ➡   $greekG\n";

my $copticH = transliterate ( "co", $hebrew );
my $ethioH  = transliterate ( "et", $hebrew );
my $greekH  = transliterate ( "el", $hebrew );
my $hebrewH = transliterate ( "he", $hebrew );

print "Hebrew ➡ Coptic ➡ Ge'ez ➡ Hebrew ➡ Greek\n";
print "   $hebrew ➡    $copticH ➡   $ethioH ➡    $hebrewH ➡   $greekH\n";

#
#  mixed script:
#
$word = "አΔמ";

my $copticX = transliterate ( "co", $hebrew );
my $ethioX  = transliterate ( "et", $hebrew );
my $greekX  = transliterate ( "el", $hebrew );
my $hebrewX = transliterate ( "he", $hebrew );

print "Mixed  ➡ Coptic ➡ Ge'ez ➡ Hebrew ➡ Greek\n";
print "  $word  ➡    $copticX ➡   $ethioX ➡    $hebrewX ➡   $greekX\n";

__END__

=head1 NAME

transliterate.pl - Demonstration of CEGH Transliteration.

=head1 SYNOPSIS

./transliterate.pl

=head1 DESCRIPTION

This is a simple demonstration script that presents transliterations,
and retransliterations between Coptic, Ethiopic, Greek and Hebrew.


=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Convert::CEGH::Gematria>

=cut
