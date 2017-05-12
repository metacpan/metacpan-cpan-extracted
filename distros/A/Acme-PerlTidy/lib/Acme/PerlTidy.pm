package Acme::PerlTidy;

use strict;
use Perl::Tidy;

our $VERSION = '0.02';

open 0 or print "Can't open '$0'\n" and exit;
my $src = join'', <0>;
my $dest;

Perl::Tidy::perltidy(
		     source      => \$src,
		     destination => $0,
		     );
#print $dest;


1;
__END__

=head1 NAME

Acme::PerlTidy - Clean code every time

=head1 SYNOPSIS

    use Acme::PerlTidy;

    # your code here.


=head1 DESCRIPTION

Acme::PerlTidy cleans up your code every time you run it.


=head1 THE AUTHOR

Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself


=head1 SEE ALSO

L<Perl::Tidy>

=cut
