package Acme::StringFormat;

use 5.010;

use strict;
use XSLoader;

our $VERSION = '0.04';

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

Acme::StringFormat - Smart interface to sprintf()

=head1 VERSION

This document describes Acme::StringFormat version 0.04

=head1 SYNOPSIS

    use Acme::StringFormat;

    # enable 'sprintf' operator in the scope

    say '[%s][%s]' % 'foo' % 'bar'; # => [foo][bar]


=head1 DESCRIPTION

I had a desire for a "format operator" of other languages.
Take boost C++ libraly for example:

	using namespace boost;
	std::cout << format("[%1%][%2]") % "foo" % "bar" << std::endl;

Now this pragmatic module provides Perl with a format operator C<%>,
which is equivalent to C<sprintf>.

=head1 INTERFACE 

=head2 C<use Acme::StringFormat;>

Enables the C<sprintf> operator in the rest of the scope;

=head2 C<no Acme::StringFormat;>

Disables the C<sprintf> operator in the rest of the scope;

=head1 DIAGNOSTICS

=over 4

=item C<< Arguments mismatch for Acme::StringFormat >>

(W printf) Too few format parameters or too many format arguments.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Acme::StringFormat requires no configuration files or environment variables.

=head1 DEPENDENCIES

Perl 5.10.0 or later, and a C compiler.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-stringformat@rt.cpan.org/>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<perlfunc/sprintf> - this module is an interface to C<sprintf>.

The following languages (or libraries) also provide C<%> format operators:

=over 4

=item C++

L<http://www.boost.org/>.

=item Ruby

L<http://www.ruby-lang.org/>.

=item Python

L<http://www.python.org/>.

=back

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji  E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
