package Basic::Coercion::XS;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.07';

require XSLoader;
XSLoader::load("Basic::Coercion::XS", $VERSION);

__END__

=head1 NAME

Basic::Coercion::XS - basic coercions

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Basic::Coercion::XS qw(StrToArray);

	my $type = StrToArray();
	my $arrayref = $type->("a b\tc\nd");
	# $arrayref is ['a', 'b', 'c', 'd']

	$type = StrToArray(by => qr/,/);
	$arrayref = $type->("a,b,c");
	# $arrayref is ['a', 'b', 'c']

=head1 EXPORT

None by default, but you can export specific functions:

	use Basic::Coercion::XS qw(StrToArray);

=head2 StrToArray

This function creates a coercion type that converts a string into an array reference.

	StrToArray(by => $regex_string);

=head2 StrToHash

This function creates a coercion type that converts a string into a hash reference.

	StrToHash->by($regex_string);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-basic-coercion-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Basic-Coercion-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Basic::Coercion::XS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Basic-Coercion-XS>

=item * Search CPAN

L<https://metacpan.org/release/Basic-Coercion-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Basic::Coercion::XS
