package Alien::LibMagic;
$Alien::LibMagic::VERSION = '0.002';
use strict;
use warnings;

use parent 'Alien::Base';

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $self = __PACKAGE__->new;
	+{
		LIBS => $self->libs,
		INC => $self->cflags,
		AUTO_INCLUDE => '#include "magic.h"',
	};
}

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::LibMagic - Alien package for the libmagic library

=head1 VERSION

version 0.002

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<file(1)>, L<file command|http://darwinsys.com/file/>, L<File::LibMagic>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: Alien package for the libmagic library

