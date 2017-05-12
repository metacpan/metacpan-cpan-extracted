use 5.005;
use strict;
use warnings;

package ARGV::ENV;
{
  $ARGV::ENV::VERSION = '1.00';
}

use Text::ParseWords ();

sub import
{
    shift;
    foreach (@_) {
	if (defined $ENV{$_} && $ENV{$_} ne '') {
	    unshift @ARGV, Text::ParseWords::shellwords($ENV{$_});
	    last;
	}
    }
}

1;
__END__

=head1 NAME

ARGV::ENV - Parse an environment variable and unshift into @ARGV

=head1 VERSION

version 1.00

=head1 SYNOPSIS

From one-liners (see L<perlrun>):

    perl -MARGV::ENV=VAR1,VAR2,... -E "..." ...

From a script:

    use ARG::ENV qw<VAR1 VAR2>;
    ...

=head1 DESCRIPTION

This module searches the first non-empty environment variable with one of the
names given at import time, parses it like the Unix shell (using
L<Text::ParseWords>::shellwords) and insert the result at the beginning of
C<@ARGV>.

This module is helpful to implement command-line scripts that take some
global config as an environnement variable containing command-line flags.

This module is named C<ARGV::ENV> (and not C<Argv::Env> or C<@ARGV::Env>)
because the perl built-in global variables C<@ARGV> and C<@ENV> are both in
upper case.

=head1 SEE ALSO

Some other modules that add magic to C<@ARGV>: L<ARGV::URL>, L<ARGV::Abs>,
L<ARGV::readonly>, L<Encode::Argv>.

=head1 AUTHOR

Olivier MenguE<eacute>, L<mailto:dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2011 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut
