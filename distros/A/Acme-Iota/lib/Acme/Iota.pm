package Acme::Iota;
use strict;
use warnings;
no strict 'refs';

our $VERSION = '0.01';

sub import {
    my $iota = 0;
    *{caller.'::iota'} = sub { (@_ ? $iota = shift : $iota)++ };
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Acme::Iota - Iota Is Acme


=head1 SYNOPSIS

    use Acme::Iota;

    use constant {
        A => iota(ord('A')),
        B => iota,
        C => iota,
    };


=head1 STATUS

Stable. No changes expected, but who knows?


=head1 DESCRIPTION

Using Acme::Iota imports a per-package counter that increases its value
on each call to C<iota>.

Providing an argument resets the counter to the specified value.


=head1 SOURCE CODE

This is quite literally all there is to the module:

    sub import {
        my $iota = 0;
        *{caller.'::iota'} = sub { (@_ ? $iota = shift : $iota)++ };
    }


=head1 SEE ALSO

L<The Go Programming Language Specification|http://golang.org/ref/spec#Iota>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Christoph Gärtner <cygx@cpan.org>

Distributed under the L<Boost Software License, Version 1.0|http://www.boost.org/LICENSE_1_0.txt>

=cut
