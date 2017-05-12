package Alien::WFDB::Install::Files;
$Alien::WFDB::Install::Files::VERSION = '0.004';
# allows other packages to use ExtUtils::Depends like so:
#   use ExtUtils::Depends;
#   my $p = new ExtUtils::Depends MyMod, Alien::WFDB;
# and their code will have all WFDB available at C level

use strict;
use warnings;

use Alien::WFDB qw(Inline);
BEGIN { *Inline = *Alien::WFDB::Inline }
sub deps { () }

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::WFDB::Install::Files

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
