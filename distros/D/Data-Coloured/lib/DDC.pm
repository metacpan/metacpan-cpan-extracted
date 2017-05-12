package DDC;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Visualize random bytes
$DDC::VERSION = '0.003';
use strict;
use warnings;
use Data::Coloured qw( pc c );
use Exporter 'import';

our @EXPORT = qw( pc c coloured poloured );

1;

__END__

=pod

=head1 NAME

DDC - Visualize random bytes

=head1 VERSION

version 0.003

=head1 DESCRIPTION

See L<Data::Coloured>

=head1 SUPPORT

IRC

  Join #vonbienenstock on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-data-coloured
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-data-coloured/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
