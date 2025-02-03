#!/usr/bin/perl -w

use utf8;
binmode(STDOUT, ":utf8");

require Convert::Number::Digits;

my $d = new Convert::Number::Digits;

my @methods = $d->toMethods;

foreach my $digit (0..9) {
	foreach my $system ( @methods ) {	
		next if ( $system eq "toWestern" );
		my $xdigit = $d->$system ( $digit );
		my $reDigit = $d->convert ( $xdigit );
		print "$system: $digit => $xdigit => $reDigit\n";
	}
}


__END__

=head1 NAME

digits.pl - Conversion Demonstration for the Digits of Many Scripts

=head1 SYNOPSIS

./digits.pl

=head1 DESCRIPTION

A demonstrator script to illustrate L<Convert::Number::Digits> usage.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
