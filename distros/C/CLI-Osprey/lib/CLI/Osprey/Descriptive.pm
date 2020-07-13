package CLI::Osprey::Descriptive;

use strict;
use warnings;

# ABSTRACT: Getopt::Long::Descriptive subclass for CLI::Osprey use
our $VERSION = '0.08'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

use Getopt::Long::Descriptive 0.100;
use CLI::Osprey::Descriptive::Usage;

our @ISA = ('Getopt::Long::Descriptive');

sub usage_class { 'CLI::Osprey::Descriptive::Usage' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Osprey::Descriptive - Getopt::Long::Descriptive subclass for CLI::Osprey use

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This class overrides L<Getopt::Long::Descriptive>'s C<usage_class> method to
L<Getopt::Long::Descriptive::Usage>, which provides customized help text. You
probably don't need to use it yourself.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
