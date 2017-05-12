package App::perlrdf;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::VERSION   = '0.006';
}

use App::Cmd::Setup -app => {
	plugins => [qw( Prompt )],
};

sub AUTHORITY
{
	my $class = ref($_[0]) || $_[0];
	no strict qw(refs);
	${"$class\::AUTHORITY"};
}

1;

__END__

=pod

=encoding utf8

=begin trustme

=item AUTHORITY

=end trustme

=head1 NAME

App::perlrdf - perlrdf command line utils

=head1 DESCRIPTION

Support library for the L<perlrdf> command-line tool.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=App-perlrdf>.

=head1 SEE ALSO

L<perlrdf>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

