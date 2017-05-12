package Acme::DoOrDie;

use strict;
use warnings;
use Carp
    qw(croak);

our $VERSION="0.001";

sub do_or_die ($ )
{
    my($name) = @_;
    my($want, @result, $result, $syntax);

    if (!defined($name) || $name eq "") {
	croak("Missing or undefined argument to require");
    }
    $want = wantarray();
    if ($want) {
	@result = do($name);
    } elsif (defined($want)) {
	$result = do($name);
    } else {
	do($name);
    }
    $syntax = $@;
    if (! exists($INC{$name})) {
	croak("Can't locate $name: $! (\@INC contains: ".join(" ",@INC).")");
    }
    if ($syntax ne "") {
	croak($syntax);
    }
    if ($want) {
	@result;
    } elsif (defined($want)) {
	$result;
    }
}

BEGIN {
    *do = \&do_or_die;
    our @EXPORT = qw(
	do_or_die
    );
    our @EXPORT_OK = qw(
	do_or_die
	do
    );
}

use Exporter
    qw(import);

1;

__END__
=head1 NAME

Acme::DoOrDie - do-file replacement that dies on errors

=head1 SYNOPSIS

 use Acme::DoOrDie;

 do_or_die("config.pl");

=head1 DESCRIPTION

Error handling for the C<do(FILENAME)> built-in function is
inconvenient.  The main problem is that you need to examine more than
just the return value to distinguish a file-not-found condition from a
successful invocation of a file that ends with these two statements:

 $! = ENOENT;
 undef;

(The L<autodie> module can't help you since it doesn't support the
C<do> function.)

This module provides the replacement function C<do_or_die> that reports
any error by throwing an exception.  The same function is also available
under the alias C<do> (not exported by default).

=head1 EXPORTS

=over

=item By default:

=over

=item do_or_die

=back

=item On request:

=over

=item do

=back

=back

=head1 AUTHOR

Bo Lindbergh E<lt>blgl@stacken.kth.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Bo Lindbergh

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

=cut

