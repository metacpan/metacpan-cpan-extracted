package Alien::UDUNITS2::Install::Files;
$Alien::UDUNITS2::Install::Files::VERSION = '0.006';
# allows other packages to use ExtUtils::Depends like so:
#   use ExtUtils::Depends;
#   my $p = new ExtUtils::Depends MyMod, Alien::UDUNITS2;
# and their code will have all UDUNITS2 available at C level

use strict;
use warnings;

use Alien::UDUNITS2 qw(Inline);
BEGIN { *Inline = *Alien::UDUNITS2::Inline }
sub deps { () }

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::UDUNITS2::Install::Files

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
