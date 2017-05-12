#!/usr/bin/perl -w

use utf8;
if ( $] >= 5.007 ) {
	binmode (STDOUT, ":utf8");
}

require Convert::Number::Roman;

my $n = new Convert::Number::Roman ( "lower" );  # "lower" set as default

print $n->convert ( 1234 ), "\n";
print $n->convert ( 1234, "upper" ), "\n";  # "upper" becomes new default
print $n->convert ( 1234 ), "\n";
$n->style ( "lower" );                      # "lower reset as default
print $n->convert ( 1234 ), "\n";

my $x = new Convert::Number::Roman ( 4321, "lower" );  # "lower" set as default
print $x->convert, "\n";
print $x->convert ( "upper" ), "\n";
$x->number ( 1234 );
print $x->convert, "\n";
print $x->convert ( "lower" ), "\n";


__END__

=head1 NAME

roman.pl - Uppercase and Lowercase Styles Demo for Roman Numerals.

=head1 SYNOPSIS

./roman.pl

=head1 DESCRIPTION

A demonstrator script to illustrate L<Convert::Number::Roman> usage.
This script shows various ways to set lowercase and uppercase styles
for Roman numerals.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
