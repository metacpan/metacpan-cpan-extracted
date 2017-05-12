package Alien::LibMagic::Install::Files;
$Alien::LibMagic::Install::Files::VERSION = '0.002';
# allows other packages to use ExtUtils::Depends like so:
#   use ExtUtils::Depends;
#   my $p = new ExtUtils::Depends MyMod, Alien::LibMagic;
# and their code will have all LibMagic available at C level

use strict;
use warnings;

use Alien::LibMagic qw(Inline);
BEGIN { *Inline = *Alien::LibMagic::Inline }
sub deps { () }

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::LibMagic::Install::Files

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
