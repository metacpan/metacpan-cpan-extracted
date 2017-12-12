package Alien::ZMQ;
# ABSTRACT: Alien::ZMQ replacement that uses Alien::ZMQ::latest
$Alien::ZMQ::VERSION = '0.001';
use strict;
use warnings;

use Alien::ZMQ::latest;
use Text::ParseWords qw/shellwords/;

sub _source {
	return 'Alien::ZMQ::latest';
}

sub inc_dir {
	join ' ', map { s/^-I//; $_ }
		grep { /^-I/ }
		shellwords( Alien::ZMQ::latest->cflags );
}

sub libs {
	Alien::ZMQ::latest->libs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::ZMQ - Alien::ZMQ replacement that uses Alien::ZMQ::latest

=head1 VERSION

version 0.001

=head1 SEE ALSO

L<Alien::ZMQ::latest>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
