package Alien::Uninum::Install::Files;
$Alien::Uninum::Install::Files::VERSION = '0.005';
# allows other packages to use ExtUtils::Depends like so:
#   use ExtUtils::Depends;
#   my $p = new ExtUtils::Depends MyMod, Alien::Uninum;
# and their code will have all Uninum available at C level

use strict;
use warnings;

use Alien::Uninum qw(Inline);
BEGIN { *Inline = *Alien::Uninum::Inline }
sub deps { () }

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Uninum::Install::Files

=head1 VERSION

version 0.005

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
