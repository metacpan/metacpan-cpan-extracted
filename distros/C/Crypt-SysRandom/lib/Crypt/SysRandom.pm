package Crypt::SysRandom;
$Crypt::SysRandom::VERSION = '0.002';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 'import';
our @EXPORT_OK = 'random_bytes';

1;

# ABSTRACT: Perl interface to system randomness

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SysRandom - Perl interface to system randomness

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Crypt::SysRandom 'random_bytes';
 my $random = random_bytes(16);

=head1 DESCRIPTION

This module uses whatever C interface is available to procure cryptographically random data from the system.

=head1 FUNCTIONS

=head2 random_bytes($count)

This will fetch a string of C<$count> random bytes containing cryptographically secure random date.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
