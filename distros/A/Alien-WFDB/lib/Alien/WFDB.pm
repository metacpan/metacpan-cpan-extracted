package Alien::WFDB;
$Alien::WFDB::VERSION = '0.004';
use strict;
use warnings;

use parent 'Alien::Base';

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $self = __PACKAGE__->new;
	+{
		LIBS => $self->libs,
		INC => $self->cflags,
		AUTO_INCLUDE => '#include "wfdb.h"',
	};
}

1;
# ABSTRACT: Alien package for the WFDB (WaveForm DataBase) library

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::WFDB - Alien package for the WFDB (WaveForm DataBase) library

=head1 VERSION

version 0.004

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<WFDB|http://physionet.org/physiotools/wfdb.shtml>, L<Bio::Physio::WFDB>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
