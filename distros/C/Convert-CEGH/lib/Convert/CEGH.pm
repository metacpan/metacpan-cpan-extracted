package Convert::CEGH;
use warnings;
use strict;
use utf8;

use Convert::CEGH::Gematria qw( enumerate );
use Convert::CEGH::Transliterate qw( transliterate );

BEGIN
{
use base qw( Exporter );
use vars qw( @EXPORT $VERSION );

	@EXPORT    = qw( enumerate transliterate );

	$VERSION = "0.04";
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

Convert::CEGH - Coptic/Ethiopic/Greek/Hebrew Gematria & Transliteration.

=head1 SYNOPSIS

  use utf8;
  binmode (STDOUT, ":utf8");
  use Convert::CEGH;

  # Print Gematria summation values:
  print "Hebrew: מדא  => ", enumerate ( "מדא" ), "\n";   # prints: '45'
  print "Ge'ez : አዳም  => ", enumerate ( "አዳም" ), "\n";   # prints: '45'
  print "Greek : ΑΔΑΜ => ", enumerate ( "ΑΔΑΜ" ), "\n";  # prints: '46'

  # Print "አዳም" under Greek transliteration:
  print transliterate ( "el", "አዳም" ), "\n";  # prints: 'ΑΔΜ'


=head1 DESCRIPTION

This module is a simple wrapper around the submodules L<Convert::CEGH::Gematria>
and L<Convert::CEGH::Transliterate> which can be used independently. This wrapper
exports two functions from the submodules, C<enumerate> and C<transliterate>, summarized
in the following:

=over 4

=item C<enumerate( string )>

Will compute a numeric value based on Gematria rules.  Gematria calculations
are applicable to Coptic, Ethiopic, Greek and Hebrew scripts.  The enumerate
function will accept a single word as an argument or a list of words.

=item C<transliterate( script, string )>

Will convert a word (or list of words) into the script specified in the
first argument.  Valid scripts values are "cop", "eth", "ell", "heb" and
"co", "et", "el", "he".  These are the 3 and 2 letter ISO 15924 script
codes for Coptic, Ethiopic, Greek and Hebrew.

=back

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Convert::CEGH::Gematria>
L<Convert::CEGH::Transliterate>

Examples included with this package:

  examples/gematria.pl
  examples/transliterate.pl

=cut
