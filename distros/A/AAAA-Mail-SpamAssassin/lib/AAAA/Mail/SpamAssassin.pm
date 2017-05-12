use strict;
use warnings;
package AAAA::Mail::SpamAssassin;
# git description: v0.001-1-g4fcbc88

BEGIN {
  $AAAA::Mail::SpamAssassin::AUTHORITY = 'cpan:SCHWIGON';
}
{
  $AAAA::Mail::SpamAssassin::VERSION = '0.002';
}
# ABSTRACT: making Mail::SpamAssassin installable

1;



=pod

=encoding utf-8

=head1 NAME

AAAA::Mail::SpamAssassin - making Mail::SpamAssassin installable

=head1 SYNOPSIS

  # in Makefile.PL

  requires 'AAAA::Mail::SpamAssassin';

=head1 DESCRIPTION

For some reason dependency resolution via the CPAN toolchains does not
work very well for L<Mail::SpamAssassin>. To install it without manual
work you need dependencies installed beforehand.

C<AAAA::Mail::SpamAssassin> is a L<Task>-style distribution that makes
sure that dependencies are installed so that L<Mail::SpamAssassin>
installation does not complain.

If you have a dependency on L<Mail::SpamAssassin> add
C<AAAA::Mail::SpamAssassin> as an additional dependency and (only) the
most crucial dependencies will be installed before
L<Mail::SpamAssassin>.

Why the C<'AAAA'>? L<CPAN> and L<CPANPLUS> install prereqs sorted
alphabetically, the C<'AAAA'> ensures that this prereq is installed
before L<Mail::SpamAssassin>. Simples.

=head1 Acknowledgements

Idea shamelessly stolen from Chris C<BinGOs> Williams'
L<AAAA::Crypt::DH|AAAA::Crypt::DH>.

=head1 SEE ALSO

L<Mail::SpamAssassin>

L<AAAA::Crypt::DH>

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

