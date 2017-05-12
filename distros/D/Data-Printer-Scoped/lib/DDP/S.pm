package DDP::S;
$DDP::S::VERSION = '0.001004';
use strict;
use warnings;

use Data::Printer::Scoped ();
use Import::Into;

sub import {
  Data::Printer::Scoped->import::into(scalar caller);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DDP::S

=head1 VERSION

version 0.001004

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
