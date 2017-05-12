package Acme::RequireModule;

use 5.010_000;
use strict;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import{
	$^H{(__PACKAGE__)} = _enter();

	return;
}
sub unimport{
	delete $^H{(__PACKAGE__)};

	return;
}


1;
__END__

=head1 NAME

Acme::RequireModule - Extends require() to accept module names

=head1 VERSION

This document describes Acme::RequireModule version 0.01.

=head1 SYNOPSIS

	use Acme::RequireModule; # This is a lexical pragma.

	foreach my $module qw(Foo Bar Baz){
		require $module; # Yes, we can!
	}

=head1 DESCRIPTION

There are too many ways to load modules :(

I wish C<require()> accepted module names!

=head1 INTERFACE

=head1 DEPENDENCIES

Perl 5.10.0 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<perlfunc>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.
Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
