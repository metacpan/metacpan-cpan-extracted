package Alien::Uninum;
$Alien::Uninum::VERSION = '0.005';
use strict;
use warnings;

use parent 'Alien::Base';

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $self = __PACKAGE__->new;
	+{
		LIBS => $self->libs,
		INC => $self->cflags,
		AUTO_INCLUDE =>
		q/#include <unicode.h>
#include <nsdefs.h>
#include <uninum.h>

/,
	};
}


1;
# ABSTRACT: Alien package for the libuninum library

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Uninum - Alien package for the libuninum library

=head1 VERSION

version 0.005

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<libuninum|http://billposer.org/Software/libuninum.html>, L<Unicode::Number>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
